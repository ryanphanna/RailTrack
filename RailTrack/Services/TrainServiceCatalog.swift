import Foundation

/// A static database that maps train numbers to official service names and branding.
struct TrainServiceCatalog {
    static let shared = TrainServiceCatalog()
    
    private let viaServices: [String: String] = [
        "1": "The Canadian", "2": "The Canadian",
        "14": "Ocean", "15": "Ocean",
        "50": "Corridor", "51": "Corridor", "52": "Corridor", "53": "Corridor",
        "54": "Corridor", "55": "Corridor", "57": "Corridor", "59": "Corridor",
        "60": "Corridor", "61": "Corridor", "62": "Corridor", "63": "Corridor",
        "64": "Corridor", "65": "Corridor", "66": "Corridor", "67": "Corridor",
        "68": "Corridor", "69": "Corridor",
        "70": "Corridor", "71": "Corridor", "72": "Corridor", "73": "Corridor",
        "75": "Corridor", "76": "Corridor", "78": "Corridor", "79": "Corridor",
        "82": "Corridor", "83": "Corridor", "84": "Corridor", "85": "Corridor",
        "87": "Corridor", "88": "Corridor",
        "97": "Corridor", "98": "Corridor"
    ]
    
    private let amtrakServices: [String: String] = [
        "1": "Sunset Limited", "2": "Sunset Limited",
        "3": "Southwest Chief", "4": "Sunset Limited",
        "5": "California Zephyr", "6": "California Zephyr",
        "7": "Empire Builder", "8": "Empire Builder",
        "11": "Coast Starlight", "14": "Coast Starlight",
        "19": "Crescent", "20": "Crescent",
        "21": "Texas Eagle", "22": "Texas Eagle",
        "29": "Capitol Limited", "30": "Capitol Limited",
        "48": "Lake Shore Limited", "49": "Lake Shore Limited",
        "50": "Cardinal", "51": "Cardinal",
        "58": "City of New Orleans", "59": "City of New Orleans",
        "63": "Maple Leaf", "64": "Maple Leaf",
        "66": "Northeast Regional", "67": "Northeast Regional",
        "91": "Silver Star", "92": "Silver Star",
        "97": "Silver Meteor", "98": "Silver Meteor",
        "350": "Wolverine", "351": "Wolverine", "352": "Wolverine", "353": "Wolverine"
    ]
    
    /// Returns the official service name for a given train number and operator.
    func getServiceName(for trainNumber: String, operatorName: String) -> String? {
        let cleanNumber = trainNumber.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if operatorName == "VIA" {
            return viaServices[cleanNumber]
        } else if operatorName == "Amtrak" {
            // Remove 'v' prefix if present from Amtraker API
            let num = cleanNumber.hasPrefix("v") ? String(cleanNumber.dropFirst()) : cleanNumber
            return amtrakServices[num]
        }
        
        return nil
    }
}
