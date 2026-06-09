import SwiftUI
import MapKit

struct HomeMapView: View {
    let records: [TripRecord]
    @Binding var position: MapCameraPosition
    let getInterpolatedCoordinate: (Trip) -> CLLocationCoordinate2D?
    
    var body: some View {
        Map(position: $position) {
            ForEach(records.map { $0.toTrip() }.filter { !$0.isUpcoming }) { trip in
                // Markers only for active trips to avoid cluttering the travel log
                if trip.isActive {
                    Annotation(trip.origin.shortName, coordinate: trip.origin.clCoordinate) {
                        StationMarker(code: trip.origin.code, isOrigin: true)
                    }
                    
                    Annotation(trip.destination.shortName, coordinate: trip.destination.clCoordinate) {
                        StationMarker(code: trip.destination.code, isOrigin: false)
                    }
                }
                
                // Route polyline
                // Active: Solid & Bold
                // Past: Faded "Travel Log" look
                let isPast = !trip.isActive
                
                let routeCoords: [CLLocationCoordinate2D] = !trip.stops.isEmpty 
                    ? trip.stops.map { $0.station.clCoordinate } 
                    : [trip.origin.clCoordinate, trip.destination.clCoordinate]
                
                MapPolyline(coordinates: routeCoords)
                    .stroke(
                        ColorTheme.operatorColor(for: trip.trainOperator).opacity(isPast ? 0.3 : 1.0),
                        lineWidth: isPast ? 2 : 4
                    )
                
                if trip.isActive, let trainCoord = getInterpolatedCoordinate(trip) {
                    Annotation("Train \(trip.trainNumber)", coordinate: trainCoord) {
                        TrainPositionMarker(operatorColor: ColorTheme.operatorColor(for: trip.trainOperator))
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}
