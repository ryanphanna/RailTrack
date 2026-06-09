import Foundation

/// A static database that maps train numbers to official service names and branding.
struct TrainServiceCatalog {
    static let shared = TrainServiceCatalog()
    
    /// Returns the official service name for a given train number and operator.
    func getServiceName(for trainNumber: String, operatorName: String) -> String? {
        let cleanNumber = trainNumber.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let numStr = cleanNumber.hasPrefix("v") ? String(cleanNumber.dropFirst()) : cleanNumber
        guard let num = Int(numStr) else { return nil }
        
        if operatorName == "VIA" {
            switch num {
            case 1...2:   return "The Canadian"
            case 14...15: return "Ocean"
            case 50...98: return "Corridor"
            case 692...693: return "Hudson Bay"
            default: return nil
            }
        } else if operatorName == "Amtrak" {
            switch num {
            case 1...2, 4: return "Sunset Limited"
            case 3:        return "Southwest Chief"
            case 5...6:    return "California Zephyr"
            case 7...8:    return "Empire Builder"
            case 11, 14:   return "Coast Starlight"
            case 19...20:  return "Crescent"
            case 21...22:  return "Texas Eagle"
            case 29...30:  return "Capitol Limited"
            case 48...49:  return "Lake Shore Limited"
            case 50...51:  return "Cardinal"
            case 58...59:  return "City of New Orleans"
            case 63...64:  return "Maple Leaf"
            case 66...67:  return "Northeast Regional"
            case 91...92:  return "Silver Star"
            case 97...98:  return "Silver Meteor"
            case 350...355: return "Wolverine"
            default: return nil
            }
        }
        
        return nil
    }
}
