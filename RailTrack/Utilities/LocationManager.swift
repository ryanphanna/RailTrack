import Foundation
import CoreLocation
import Combine

/// A thread-safe, SwiftUI-friendly helper to manage device location updates.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isTrackingEnabled: Bool = false {
        didSet {
            if !isTrackingEnabled {
                stopUpdating()
                stopMonitoringAllStations()
            }
        }
    }
    
    enum PowerMode {
        case high       // Best accuracy, for station arrivals
        case navigation // Balanced, for active journey recording
        case efficient  // Significant changes only, for mid-trip
    }
    
    override init() {
        super.init()
        manager.delegate = self
        setPowerMode(.navigation)
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true // Let iOS manage sleep
        manager.showsBackgroundLocationIndicator = true
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func setPowerMode(_ mode: PowerMode) {
        switch mode {
        case .high:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 10
        case .navigation:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter = 100
        case .efficient:
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = 500
        }
    }
    
    func startMonitoringStation(_ station: Station) {
        let region = CLCircularRegion(
            center: station.clCoordinate,
            radius: 1000, // 1km radius
            identifier: "station-\(station.id)"
        )
        region.notifyOnEntry = true
        manager.startMonitoring(for: region)
    }
    
    func stopMonitoringAllStations() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
    }
    
    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier.hasPrefix("station-") {
            print("[LocationManager] Entered station region: \(region.identifier)")
            // Boost accuracy for precision arrival detection
            setPowerMode(.high)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier.hasPrefix("station-") {
            print("[LocationManager] Exited station region: \(region.identifier)")
            // Drop accuracy to save battery while in transit
            setPowerMode(.navigation)
        }
    }
