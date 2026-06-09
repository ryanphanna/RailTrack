import Foundation
import CoreLocation
import Combine
import SwiftData

/// Monitors location updates to detect proximity to stations and trigger trip events.
@MainActor
final class StationProximityManager: ObservableObject {
    static let shared = StationProximityManager()
    
    @Published var nearbyStation: Station?
    @Published var isAtOrigin: Bool = false
    @Published var isAtDestination: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let proximityThreshold: CLLocationDistance = 500 // 500 meters
    
    @Published var activeTrip: Trip?
    
    private init() {
        LocationManager.shared.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { [weak self] in
                    await self?.checkProximity(to: location)
                }
            }
            .store(in: &cancellables)
            
        $activeTrip
            .sink { [weak self] trip in
                if let trip = trip {
                    // Set up geofences for origin and destination to save battery
                    LocationManager.shared.stopMonitoringAllStations()
                    LocationManager.shared.startMonitoringStation(trip.origin)
                    LocationManager.shared.startMonitoringStation(trip.destination)
                    
                    // Start in efficient mode if trip is active but we're not at a station
                    LocationManager.shared.setPowerMode(.navigation)
                    
                    if let location = LocationManager.shared.location {
                        self?.updateProximity(for: trip, at: location)
                    }
                } else {
                    LocationManager.shared.stopMonitoringAllStations()
                    LocationManager.shared.setPowerMode(.navigation)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Checks if the user is near any stations, especially for the active trip.
    func checkProximity(to location: CLLocation) async {
        // 1. Update proximity for active trip if one exists
        if let trip = activeTrip {
            updateProximity(for: trip, at: location)
        }
        
        // 2. Find nearest station from database
        let nearest = StationDatabase.shared.search("").compactMap { station -> (Station, CLLocationDistance)? in
            let stationLoc = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
            let distance = stationLoc.distance(from: location)
            return distance < 1000 ? (station, distance) : nil
        }.sorted { $0.1 < $1.1 }.first
        
        self.nearbyStation = nearest?.0
    }
    
    /// Specific check for an active trip
    func updateProximity(for trip: Trip, at location: CLLocation) {
        // Only process proximity if journey tracking is enabled
        guard UserDefaults.standard.bool(forKey: "isGPSTrackingEnabled") else {
            isAtOrigin = false
            isAtDestination = false
            return
        }
        
        let userLoc = location
        let originLoc = CLLocation(latitude: trip.origin.coordinate.latitude, longitude: trip.origin.coordinate.longitude)
        let destLoc = CLLocation(latitude: trip.destination.coordinate.latitude, longitude: trip.destination.coordinate.longitude)
        
        isAtOrigin = userLoc.distance(from: originLoc) < proximityThreshold
        isAtDestination = userLoc.distance(from: destLoc) < proximityThreshold
        
        if isAtDestination && trip.isActive {
            // Potential for auto-complete trip logic here
            print("[Proximity] User arrived at destination: \(trip.destination.name)")
        }
    }
}
