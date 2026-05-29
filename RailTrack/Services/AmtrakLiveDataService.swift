import Foundation
import SwiftData
import SwiftUI

/// Service to fetch, sync, and lookup Amtrak live positions and schedules.
/// Uses the unofficial Amtraker v3 API.
final class AmtrakLiveDataService: ObservableObject {
    
    static let shared = AmtrakLiveDataService()
    
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
    
    struct AmtrakTrain: Codable {
        let trainNum: String
        let trainID: String
        let lat: Double?
        let lon: Double?
        let velocity: Double?
        let heading: String?
        let trainState: String?
        let stations: [AmtrakStationStop]
    }

    struct AmtrakStationStop: Codable {
        let name: String
        let code: String
        let tz: String
        let schArr: String?
        let schDep: String?
        let arr: String?
        let dep: String?
        let status: String?
        let platform: String?
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
                print("[AmtrakLiveDataService] Live fetch failed: \(error.localizedDescription). Falling back to local snapshot.")
                data = loadLocalSnapshot()
            }
        }
        
        guard let rawData = data else {
            print("[AmtrakLiveDataService] No data loaded.")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let feed = try decoder.decode([String: [AmtrakTrain]].self, from: rawData)
            syncWithDatabase(feed: feed, modelContext: modelContext)
        } catch {
            print("[AmtrakLiveDataService] JSON decoding failed: \(error)")
        }
    }
    
    private func syncWithDatabase(feed: [String: [AmtrakTrain]], modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TripRecord>()
        guard let records = try? modelContext.fetch(descriptor) else { return }
        
        var newLiveStops: [UUID: [Stop]] = [:]
        
        for record in records {
            guard record.trainOperator.uppercased() == "AMTRAK" else { continue }
            
            let trainNumber = record.trainNumber
            guard let trains = feed[trainNumber] else { continue }
            
            var matchedTrain: AmtrakTrain? = nil
            let tripDateStr = departureDateString(for: record)
            
            for train in trains {
                guard let firstStation = train.stations.first else { continue }
                guard let schDepStr = firstStation.schDep else { continue }
                
                let schDepDateStr = String(schDepStr.prefix(10))
                if schDepDateStr == tripDateStr {
                    matchedTrain = train
                    break
                }
            }
            
            if let matched = matchedTrain {
                print("[AmtrakLiveDataService] Matched train \(record.trainNumber) on date \(tripDateStr)")
                
                record.liveLatitude = matched.lat
                record.liveLongitude = matched.lon
                record.liveSpeed = matched.velocity.map(Int.init)
                record.liveUpdated = Date()
                
                // Calculate delay minutes based on arrival/departure at the last visited stop
                var calculatedDelay = 0
                if let lastVisited = matched.stations.last(where: { $0.status == "Departed" || $0.status == "Station" }),
                   let arrStr = lastVisited.arr,
                   let schArrStr = lastVisited.schArr,
                   let arrDate = parseISO8601Date(arrStr),
                   let schArrDate = parseISO8601Date(schArrStr) {
                    let diffSeconds = arrDate.timeIntervalSince(schArrDate)
                    calculatedDelay = Int(diffSeconds / 60)
                } else if let firstEnroute = matched.stations.first(where: { $0.status == "Enroute" }),
                          let arrStr = firstEnroute.arr,
                          let schArrStr = firstEnroute.schArr,
                          let arrDate = parseISO8601Date(arrStr),
                          let schArrDate = parseISO8601Date(schArrStr) {
                    let diffSeconds = arrDate.timeIntervalSince(schArrDate)
                    calculatedDelay = Int(diffSeconds / 60)
                }
                
                record.delayMinutes = calculatedDelay
                if calculatedDelay > 0 {
                    record.statusRaw = "delayed"
                } else if matched.stations.allSatisfy({ $0.status == "Departed" }) {
                    record.statusRaw = "completed"
                } else if matched.stations.first?.status == "Departed" {
                    record.statusRaw = "onTime"
                } else {
                    record.statusRaw = "scheduled"
                }
                
                // Map the stops timeline
                var stopsList: [Stop] = []
                for (index, amtrakStop) in matched.stations.enumerated() {
                    let station = resolveStation(code: amtrakStop.code, name: amtrakStop.name)
                    let isOrigin = index == 0
                    let isDestination = index == matched.stations.count - 1
                    
                    let scheduledArr = parseISO8601Date(amtrakStop.schArr)
                    let estimatedArr = parseISO8601Date(amtrakStop.arr)
                    
                    let scheduledDep = parseISO8601Date(amtrakStop.schDep)
                    let estimatedDep = parseISO8601Date(amtrakStop.dep)
                    
                    let stop = Stop(
                        id: UUID(),
                        station: station,
                        scheduledArrival: scheduledArr,
                        scheduledDeparture: scheduledDep,
                        actualArrival: estimatedArr,
                        actualDeparture: estimatedDep,
                        platform: amtrakStop.platform?.isEmpty == false ? amtrakStop.platform : nil,
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
        let stationId = "AMT-\(code)"
        if let found = StationDatabase.shared.stations.first(where: { $0.id == stationId }) {
            return found
        }
        return Station(
            id: stationId,
            name: name,
            shortName: name,
            code: code,
            coordinate: Coordinate(latitude: 0, longitude: 0),
            timezone: "America/New_York",
            railOperator: "Amtrak",
            city: name,
            country: "US"
        )
    }
    
    // MARK: - Schedule Lookup
    
    func lookupTrainSchedule(trainNumber: String, departureDate: Date) async -> AmtrakTrain? {
        let rawData: Data?
        if useLocalSnapshot {
            rawData = loadLocalSnapshot()
        } else {
            do {
                rawData = try await fetchLiveFeed()
            } catch {
                print("[AmtrakLiveDataService] Live fetch failed during lookup: \(error.localizedDescription). Falling back to local snapshot.")
                rawData = loadLocalSnapshot()
            }
        }
        guard let data = rawData else { return nil }
        
        do {
            let decoder = JSONDecoder()
            let feed = try decoder.decode([String: [AmtrakTrain]].self, from: data)
            
            guard let trains = feed[trainNumber] else { return nil }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let targetDateStr = formatter.string(from: departureDate)
            
            for train in trains {
                guard let firstStation = train.stations.first else { continue }
                guard let schDepStr = firstStation.schDep else { continue }
                
                let schDepDateStr = String(schDepStr.prefix(10))
                
                if schDepDateStr == targetDateStr {
                    return train
                }
            }
        } catch {
            print("[AmtrakLiveDataService] Parse failed during lookup: \(error)")
        }
        return nil
    }
    
    private func loadLocalSnapshot() -> Data? {
        guard let url = Bundle.main.url(forResource: "amtrak_snapshot", withExtension: "json") else {
            print("[AmtrakLiveDataService] Local snapshot amtrak_snapshot.json not found in bundle.")
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    private func fetchLiveFeed() async throws -> Data {
        let url = URL(string: "https://api.amtraker.com/v3/trains")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
    
    func parseISO8601Date(_ string: String?) -> Date? {
        guard let string = string else { return nil }
        return isoFormatter.date(from: string)
    }
}

