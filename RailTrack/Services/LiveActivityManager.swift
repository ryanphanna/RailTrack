import Foundation
import Combine
#if os(iOS)
import ActivityKit
#endif

@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    #if os(iOS)
    private var activeActivity: Activity<TripActivityAttributes>? = nil
    private var currentTripId: UUID? = nil
    #endif
    
    private init() {}
    
    func syncActiveTrip(_ trip: Trip?) {
        #if os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        guard let trip = trip else {
            if currentTripId != nil {
                endActivity()
                currentTripId = nil
            }
            return
        }
        
        if currentTripId == trip.id {
            updateActivity(for: trip)
        } else {
            currentTripId = trip.id
            startActivity(for: trip)
        }
        #endif
    }
    
    func startActivity(for trip: Trip) {
        #if os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // End any active one first
        endActivity()
        
        let attributes = TripActivityAttributes(
            trainNumber: trip.trainNumber,
            trainOperator: trip.trainOperator,
            originCode: trip.origin.code,
            destinationCode: trip.destination.code
        )
        
        let stops = getLiveStops(for: trip)
        let state = TripActivityAttributes.ContentState(
            statusLabel: trip.status.label,
            delayMinutes: trip.delayMinutes ?? 0,
            isNegativeStatus: trip.status.isNegative,
            nextStationName: stops.first(where: { $0.actualArrival == nil })?.station.name ?? trip.destination.name,
            estimatedArrivalTime: trip.scheduledArrival.addingTimeInterval(Double(trip.delayMinutes ?? 0) * 60),
            progressFraction: currentProgressFraction(for: trip)
        )
        
        do {
            let content = ActivityContent(state: state, staleDate: nil)
            let activity = try Activity<TripActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            self.activeActivity = activity
            print("[LiveActivity] Started Activity ID: \(activity.id)")
        } catch {
            print("[LiveActivity] Error starting activity: \(error.localizedDescription)")
        }
        #endif
    }
    
    func updateActivity(for trip: Trip) {
        #if os(iOS)
        guard let activity = activeActivity else { return }
        
        let stops = getLiveStops(for: trip)
        let state = TripActivityAttributes.ContentState(
            statusLabel: trip.status.label,
            delayMinutes: trip.delayMinutes ?? 0,
            isNegativeStatus: trip.status.isNegative,
            nextStationName: stops.first(where: { $0.actualArrival == nil })?.station.name ?? trip.destination.name,
            estimatedArrivalTime: trip.scheduledArrival.addingTimeInterval(Double(trip.delayMinutes ?? 0) * 60),
            progressFraction: currentProgressFraction(for: trip)
        )
        
        Task {
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.update(content)
            print("[LiveActivity] Updated Activity ID: \(activity.id)")
        }
        #endif
    }
    
    func endActivity() {
        #if os(iOS)
        guard let activity = activeActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activeActivity = nil
            print("[LiveActivity] Ended Activity")
        }
        #endif
    }
    
    private func getLiveStops(for trip: Trip) -> [Stop] {
        if trip.trainOperator.uppercased() == "VIA" {
            return VIALiveDataService.shared.liveStops[trip.id] ?? []
        } else if trip.trainOperator.uppercased() == "AMTRAK" {
            return AmtrakLiveDataService.shared.liveStops[trip.id] ?? []
        }
        return []
    }
    
    private func currentProgressFraction(for trip: Trip) -> Double {
        let now = Date()
        let dep = trip.scheduledDeparture
        let arr = trip.scheduledArrival
        let total = arr.timeIntervalSince(dep)
        guard total > 0 else { return 0.0 }
        let elapsed = now.timeIntervalSince(dep)
        return max(0.0, min(1.0, elapsed / total))
    }
}
