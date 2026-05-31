import Foundation
import SwiftData
import SwiftUI

/// Service to fetch and parse VIA Rail live tracking data.
/// Maps TSI Mobile JSON parameters to SwiftData model properties.
final class VIALiveDataService: ObservableObject {
    
    static let shared = VIALiveDataService()
    
    @Published var liveStops: [UUID: [Stop]] = [:]
    @Published var isFetching = false
    
    // Toggle for Stage 1 (Static Snapshot) vs Stage 2 (Live Networking)
    var useLocalSnapshot: Bool = false
    
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private init() {}
    
    // MARK: - API Structs
    
    struct VIALiveTrain: Codable {
        let lat: Double?
        let lng: Double?
        let speed: Int?
        let direction: Double?
        let poll: String?
        let departed: Bool?
        let arrived: Bool?
        let from: String?
        let to: String?
        let instance: String // yyyy-MM-dd
        let times: [VIALiveStopTime]
    }

    struct VIALiveStopTime: Codable {
        let station: String
        let code: String
        let estimated: String?
        let scheduled: String?
        let eta: String?
        let arrival: VIALiveTimeEstimate?
        let departure: VIALiveTimeEstimate?
        let diffMin: Int?
    }

    struct VIALiveTimeEstimate: Codable {
        let estimated: String?
        let scheduled: String?
    }
    
    // MARK: - Fetching & Syncing
    
    @MainActor
    func fetchAndSync(modelContext: ModelContext) async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        
        let data: Data?
        if useLocalSnapshot {
            data = loadLocalSnapshot()
        } else {
            do {
                data = try await fetchLiveFeed()
            } catch {
                print("[VIALiveDataService] Live fetch failed: \(error.localizedDescription). Falling back to local snapshot.")
                data = loadLocalSnapshot()
            }
        }
        
        guard let rawData = data else {
            print("[VIALiveDataService] No data loaded.")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let feed = try decoder.decode([String: VIALiveTrain].self, from: rawData)
            syncWithDatabase(feed: feed, modelContext: modelContext)
        } catch {
            print("[VIALiveDataService] JSON decoding failed: \(error)")
        }
    }
    
    private func loadLocalSnapshot() -> Data? {
        guard let url = Bundle.main.url(forResource: "viasnapshot", withExtension: "json") else {
            print("[VIALiveDataService] Local snapshot viasnapshot.json not found in bundle.")
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    private func fetchLiveFeed() async throws -> Data {
        let url = URL(string: "https://tsimobile.viarail.ca/data/allData.json")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
    
    // MARK: - Helpers & Matching Logic
    
    private func syncWithDatabase(feed: [String: VIALiveTrain], modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TripRecord>()
        guard let records = try? modelContext.fetch(descriptor) else { return }
        
        var newLiveStops: [UUID: [Stop]] = [:]
        
        for record in records {
            guard record.trainOperator.uppercased() == "VIA" else { continue }
            guard let tripTrainInt = Int(record.trainNumber) else { continue }
            
            var matchedTrain: VIALiveTrain? = nil
            
            for (key, train) in feed {
                let parts = key.split(separator: " ")
                guard let trainPart = parts.first, let feedTrainInt = Int(trainPart) else { continue }
                
                if tripTrainInt == feedTrainInt {
                    let tripDateStr = departureDateString(for: record)
                    if train.instance == tripDateStr {
                        matchedTrain = train
                        break
                    }
                }
            }
            
            if let matched = matchedTrain {
                print("[VIALiveDataService] Matched train \(record.trainNumber) on date \(matched.instance)")
                
                record.liveLatitude = matched.lat
                record.liveLongitude = matched.lng
                record.liveSpeed = matched.speed
                record.liveUpdated = Date()
                
                // Calculate delay minutes
                var calculatedDelay = 0
                if let lastStopWithDiff = matched.times.last(where: { $0.diffMin != nil }) {
                    calculatedDelay = lastStopWithDiff.diffMin ?? 0
                }
                
                record.delayMinutes = calculatedDelay
                if calculatedDelay > 0 {
                    record.statusRaw = "delayed"
                } else if matched.arrived == true {
                    record.statusRaw = "completed"
                } else if matched.departed == true {
                    record.statusRaw = "onTime"
                } else {
                    record.statusRaw = "scheduled"
                }
                
                // Map the stops timeline
                var stopsList: [Stop] = []
                for (index, time) in matched.times.enumerated() {
                    let station = resolveStation(code: time.code, name: time.station)
                    let isOrigin = index == 0
                    let isDestination = index == matched.times.count - 1
                    
                    let scheduledArr = parseISO8601Date(time.arrival?.scheduled ?? time.scheduled)
                    let estimatedArr = parseISO8601Date(time.arrival?.estimated ?? time.estimated)
                    
                    let scheduledDep = parseISO8601Date(time.departure?.scheduled ?? time.scheduled)
                    let estimatedDep = parseISO8601Date(time.departure?.estimated ?? time.estimated)
                    
                    let stop = Stop(
                        id: UUID(),
                        station: station,
                        scheduledArrival: scheduledArr,
                        scheduledDeparture: scheduledDep,
                        actualArrival: estimatedArr,
                        actualDeparture: estimatedDep,
                        platform: nil,
                        isOrigin: isOrigin,
                        isDestination: isDestination
                    )
                    stopsList.append(stop)
                }
                
                newLiveStops[record.id] = stopsList
            }
        }
        
        try? modelContext.save()
        
        self.liveStops = newLiveStops
    }
    
    private func departureDateString(for trip: TripRecord) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let tz = TimeZone(identifier: trip.originTimezone) {
            formatter.timeZone = tz
        }
        return formatter.string(from: trip.scheduledDeparture)
    }
    
    private func resolveStation(code: String, name: String) -> Station {
        let stationId = "VIA-\(code)"
        if let found = StationDatabase.shared.stations.first(where: { $0.id == stationId }) {
            return found
        }
        return Station(
            id: stationId,
            name: name,
            shortName: name,
            code: code,
            coordinate: Coordinate(latitude: 0, longitude: 0),
            timezone: "America/Toronto",
            railOperator: "VIA",
            city: name,
            country: "CA"
        )
    }
    
    func parseISO8601Date(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        return isoFormatter.date(from: string)
    }

    // MARK: - Schedule Lookup

    func lookupTrainSchedule(trainNumber: String, departureDate: Date) async -> VIALiveTrain? {
        let rawData: Data?
        if useLocalSnapshot {
            rawData = loadLocalSnapshot()
        } else {
            do {
                rawData = try await fetchLiveFeed()
            } catch {
                print("[VIALiveDataService] Live fetch failed during lookup: \(error.localizedDescription). Falling back to local snapshot.")
                rawData = loadLocalSnapshot()
            }
        }
        guard let data = rawData else { return nil }
        
        do {
            let decoder = JSONDecoder()
            let feed = try decoder.decode([String: VIALiveTrain].self, from: data)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: departureDate)
            
            guard let trainInt = Int(trainNumber) else { return nil }
            
            var fallbackTrain: VIALiveTrain? = nil
            
            for (key, train) in feed {
                let parts = key.split(separator: " ")
                guard let trainPart = parts.first, let feedTrainInt = Int(trainPart) else { continue }
                
                if trainInt == feedTrainInt {
                    if train.instance == dateStr {
                        return train
                    }
                    fallbackTrain = train
                }
            }
            
            return fallbackTrain
        } catch {
            print("[VIALiveDataService] Parse failed during lookup: \(error)")
        }
        return nil
    }

    func findTrains(originCode: String, destinationCode: String, date: Date) async -> [String: VIALiveTrain] {
        let rawData: Data?
        if useLocalSnapshot {
            rawData = loadLocalSnapshot()
        } else {
            do {
                rawData = try await fetchLiveFeed()
            } catch {
                rawData = loadLocalSnapshot()
            }
        }
        guard let data = rawData else { return [:] }
        
        do {
            let decoder = JSONDecoder()
            let feed = try decoder.decode([String: VIALiveTrain].self, from: data)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: date)
            
            var matches: [String: VIALiveTrain] = [:]
            
            for (key, train) in feed {
                let parts = key.split(separator: " ")
                guard let trainPart = parts.first, let _ = Int(trainPart) else { continue }
                
                guard train.instance == dateStr else { continue }
                
                let times = train.times
                if let originIndex = times.firstIndex(where: { $0.code == originCode }),
                   let destIndex = times.firstIndex(where: { $0.code == destinationCode }),
                   originIndex < destIndex {
                    let cleanNumber = String(trainPart)
                    matches[cleanNumber] = train
                }
            }
            
            // Fallback: If no matches on exact date (common for snapshots/offline), try matching without date constraint
            if matches.isEmpty {
                for (key, train) in feed {
                    let parts = key.split(separator: " ")
                    guard let trainPart = parts.first, let _ = Int(trainPart) else { continue }
                    
                    let times = train.times
                    if let originIndex = times.firstIndex(where: { $0.code == originCode }),
                       let destIndex = times.firstIndex(where: { $0.code == destinationCode }),
                       originIndex < destIndex {
                        let cleanNumber = String(trainPart)
                        matches[cleanNumber] = train
                    }
                }
            }
            
            return matches
        } catch {
            print("[VIALiveDataService] findTrains failed: \(error)")
        }
        return [:]
    }

}

