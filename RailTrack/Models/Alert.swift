import Foundation

struct TrainAlert: Identifiable, Codable {
    let id: UUID
    var tripID: UUID
    var type: AlertType
    var message: String
    var issuedAt: Date
    var isRead: Bool

    enum AlertType: String, Codable {
        case delay
        case platformChange
        case cancellation
        case serviceUpdate
        case onboardInfo

        var icon: String {
            switch self {
            case .delay: return "clock.badge.exclamationmark"
            case .platformChange: return "arrow.triangle.swap"
            case .cancellation: return "xmark.circle.fill"
            case .serviceUpdate: return "info.circle.fill"
            case .onboardInfo: return "megaphone.fill"
            }
        }
    }
}
