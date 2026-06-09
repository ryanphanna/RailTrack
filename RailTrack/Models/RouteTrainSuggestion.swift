import Foundation

struct RouteTrainSuggestion: Identifiable {
    let id = UUID()
    let trainNumber: String
    let operatorName: String
    let originCode: String
    let destinationCode: String
    let scheduledDeparture: Date?
    let scheduledArrival: Date?
    
    var serviceName: String? {
        TrainServiceCatalog.shared.getServiceName(for: trainNumber, operatorName: operatorName)
    }
}
