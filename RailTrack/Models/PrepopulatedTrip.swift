import Foundation

struct PrepopulatedTrip: Identifiable {
    var id: String { "\(trainNumber)-\(operatorName)-\(origin?.id ?? "")-\(destination?.id ?? "")" }
    let origin: Station?
    let destination: Station?
    let trainNumber: String
    let operatorName: String
}
