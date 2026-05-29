import Foundation

/// Service to lookup Amtrak scheduled service timetables.
/// Uses the unofficial Amtraker v3 API.
final class AmtrakLiveDataService: ObservableObject {
    
    static let shared = AmtrakLiveDataService()
    
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
            
            // Amtraker keys trains by string train number
            guard let trains = feed[trainNumber] else { return nil }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let targetDateStr = formatter.string(from: departureDate)
            
            for train in trains {
                guard let firstStation = train.stations.first else { continue }
                guard let schDepStr = firstStation.schDep else { continue }
                
                // schDep is ISO8601 string prefix matching yyyy-MM-dd
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
        // Amtraker uses ISO8601 format with timezone offsets, so we use a custom formatter with time zone support if needed
        // ISO8601DateFormatter defaults to handling offsets correctly.
        return isoFormatter.date(from: string)
    }
}
