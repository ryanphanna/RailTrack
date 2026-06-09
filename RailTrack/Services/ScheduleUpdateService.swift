import Foundation
import SwiftData

/// Automatically refreshes saved trip schedules as their departure date approaches.
@MainActor
final class ScheduleUpdateService {
    static let shared = ScheduleUpdateService()
    
    private init() {}
    
    /// Checks all upcoming trips and refreshes them if they are now within the live data window (today).
    func refreshUpcomingTrips(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<TripRecord>()
        do {
            let records = try modelContext.fetch(descriptor)
            let upcoming = records.filter { $0.toTrip().isUpcoming && !$0.toTrip().isFuture }
            
            print("[ScheduleUpdateService] Checking \(upcoming.count) trips for live updates...")
            
            for record in upcoming {
                await refreshTrip(record: record)
            }
            
            try modelContext.save()
        } catch {
            print("[ScheduleUpdateService] Failed to fetch or save: \(error)")
        }
    }
    
    private func refreshTrip(record: TripRecord) async {
        let trip = record.toTrip()
        
        // Only refresh from live data if we are within 24 hours of departure
        guard !trip.isFuture else { return }
        
        if trip.trainOperator == "VIA" {
            if let liveTrain = await VIALiveDataService.shared.lookupTrainSchedule(trainNumber: trip.trainNumber, departureDate: trip.scheduledDeparture) {
                updateRecord(record, with: liveTrain)
            }
        } else if trip.trainOperator == "Amtrak" {
            if let liveTrain = await AmtrakLiveDataService.shared.lookupTrainSchedule(trainNumber: trip.trainNumber, departureDate: trip.scheduledDeparture) {
                updateRecord(record, with: liveTrain)
            }
        }
    }
    
    private func updateRecord(_ record: TripRecord, with viaTrain: VIALiveDataService.VIALiveTrain) {
        if let first = viaTrain.times.first, let last = viaTrain.times.last {
            // Update scheduled times in case the official timetable changed
            if let depStr = first.departure?.scheduled ?? first.scheduled, 
               let depDate = VIALiveDataService.shared.parseISO8601Date(depStr) {
                record.scheduledDeparture = depDate
            }
            if let arrStr = last.arrival?.scheduled ?? last.scheduled,
               let arrDate = VIALiveDataService.shared.parseISO8601Date(arrStr) {
                record.scheduledArrival = arrDate
            }
            print("[ScheduleUpdateService] Updated VIA \(record.trainNumber) schedule from live data.")
        }
    }
    
    private func updateRecord(_ record: TripRecord, with amtrakTrain: AmtrakLiveDataService.AmtrakTrain) {
        if let first = amtrakTrain.stations.first, let last = amtrakTrain.stations.last {
            if let depDate = AmtrakLiveDataService.shared.parseISO8601Date(first.schDep) {
                record.scheduledDeparture = depDate
            }
            if let arrDate = AmtrakLiveDataService.shared.parseISO8601Date(last.schArr) {
                record.scheduledArrival = arrDate
            }
            print("[ScheduleUpdateService] Updated Amtrak \(record.trainNumber) schedule from live data.")
        }
    }
}
