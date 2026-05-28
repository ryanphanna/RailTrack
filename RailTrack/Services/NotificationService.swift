import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    func scheduleDelayAlert(for trip: Trip, delayMinutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "VIA \(trip.trainNumber) delayed"
        content.body = "Running \(delayMinutes) minutes late. New arrival: \(trip.scheduledArrival.addingTimeInterval(Double(delayMinutes) * 60).timeString)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "delay-\(trip.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDepartureReminder(for trip: Trip, minutesBefore: Int = 30) {
        let fireDate = trip.scheduledDeparture.addingTimeInterval(Double(-minutesBefore) * 60)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(trip.trainOperator) \(trip.trainNumber) in \(minutesBefore) min"
        content.body = "\(trip.origin.shortName) → \(trip.destination.shortName) · Platform \(trip.currentPlatform ?? "TBA")"
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "depart-\(trip.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotifications(for trip: Trip) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["delay-\(trip.id)", "depart-\(trip.id)"]
        )
    }
}
