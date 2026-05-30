import Foundation
import SwiftData
import SwiftUI

/// Service to fetch, sync, and lookup GO Transit schedules and live tracking.
/// Uses a local snapshot resource to simulate GTFS-RT real-time train status.
final class GOLiveDataService: ObservableObject {
    
    static let shared = GOLiveDataService()
    
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
    
    // MARK: - API Structs (Matching VIA Rail structure for compatibility)
    
    struct GOLiveTrain: Codable {
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
        let times: [GOLiveStopTime]
    }

    struct GOLiveStopTime: Codable {
        let station: String
        let code: String
        let estimated: String?
        let scheduled: String?
        let eta: String?
        let arrival: GOLiveTimeEstimate?
        let departure: GOLiveTimeEstimate?
        let diffMin: Int?
    }

    struct GOLiveTimeEstimate: Codable {
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
                print("[GOLiveDataService] Live fetch failed: \(error.localizedDescription). Falling back to local snapshot.")
                data = loadLocalSnapshot()
            }
        }
        
        guard let rawData = data else {
            print("[GOLiveDataService] No data loaded.")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let feed = try decoder.decode([String: GOLiveTrain].self, from: rawData)
            syncWithDatabase(feed: feed, modelContext: modelContext)
        } catch {
            print("[GOLiveDataService] JSON decoding failed: \(error)")
        }
    }
    
    private func loadLocalSnapshot() -> Data? {
        guard let url = Bundle.main.url(forResource: "go_snapshot", withExtension: "json") else {
            print("[GOLiveDataService] Local snapshot go_snapshot.json not found in bundle.")
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    private func fetchLiveFeed() async throws -> Data {
        // Fallback to local snapshot since real-time Metrolinx API requires key registration.
        // This acts as a robust GTFS-RT / Open Data API stub.
        if let data = loadLocalSnapshot() {
            return data
        }
        throw URLError(.fileDoesNotExist)
    }
    
    // MARK: - Helpers & Matching Logic
    
    private func syncWithDatabase(feed: [String: GOLiveTrain], modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TripRecord>()
        guard let records = try? modelContext.fetch(descriptor) else { return }
        
        var newLiveStops: [UUID: [Stop]] = [:]
        
        for record in records {
            guard record.trainOperator.uppercased() == "GO" else { continue }
            guard let tripTrainInt = Int(record.trainNumber) else { continue }
            
            var matchedTrain: GOLiveTrain? = nil
            
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
                print("[GOLiveDataService] Matched GO train \(record.trainNumber) on date \(matched.instance)")
                
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
    
    func resolveStation(code: String, name: String) -> Station {
        // Try matching by code for GO operator
        if let found = StationDatabase.shared.stations.first(where: { $0.code == code && $0.railOperator == "GO" }) {
            return found
        }
        // Handle Toronto Union Station (since its railOperator is "VIA")
        if code == "TOR" || code == "TRTO" {
            if let found = StationDatabase.shared.stations.first(where: { $0.id == "VIA-TRTO" }) {
                return found
            }
        }
        
        let stationId = "GO-\(code)"
        if let found = StationDatabase.shared.stations.first(where: { $0.id == stationId }) {
            return found
        }
        return Station(
            id: stationId,
            name: name,
            shortName: name,
            code: code,
            coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806), // Toronto Union fallback
            timezone: "America/Toronto",
            railOperator: "GO",
            city: name,
            country: "CA"
        )
    }
    
    func parseISO8601Date(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        return isoFormatter.date(from: string)
    }

    // MARK: - Schedule Lookup

    func lookupTrainSchedule(trainNumber: String, departureDate: Date) async -> GOLiveTrain? {
        let rawData: Data?
        if useLocalSnapshot {
            rawData = loadLocalSnapshot()
        } else {
            do {
                rawData = try await fetchLiveFeed()
            } catch {
                print("[GOLiveDataService] Live fetch failed during lookup: \(error.localizedDescription). Falling back to local snapshot.")
                rawData = loadLocalSnapshot()
            }
        }
        guard let data = rawData else { return nil }
        
        do {
            let decoder = JSONDecoder()
            let feed = try decoder.decode([String: GOLiveTrain].self, from: data)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: departureDate)
            
            guard let trainInt = Int(trainNumber) else { return nil }
            
            for (key, train) in feed {
                let parts = key.split(separator: " ")
                guard let trainPart = parts.first, let feedTrainInt = Int(trainPart) else { continue }
                
                if trainInt == feedTrainInt && train.instance == dateStr {
                    return train
                }
            }
        } catch {
            print("[GOLiveDataService] Parse failed during lookup: \(error)")
        }
        return nil
    }
}
