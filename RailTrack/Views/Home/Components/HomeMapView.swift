import SwiftUI
import MapKit

struct HomeMapView: View {
    let records: [TripRecord]
    @Binding var position: MapCameraPosition
    let getInterpolatedCoordinate: (Trip) -> CLLocationCoordinate2D?
    
    var body: some View {
        Map(position: $position) {
            ForEach(records.map { $0.toTrip() }) { trip in
                // Markers only for active/upcoming or most recent past to avoid clutter
                if trip.isActive || trip.isUpcoming {
                    Annotation(trip.origin.shortName, coordinate: trip.origin.clCoordinate) {
                        StationMarker(code: trip.origin.code, isOrigin: true)
                    }
                    
                    Annotation(trip.destination.shortName, coordinate: trip.destination.clCoordinate) {
                        StationMarker(code: trip.destination.code, isOrigin: false)
                    }
                }
                
                // Route polyline
                // Active/Upcoming: Solid & Bold
                // Past: Faded "Travel Log" look
                let isPast = !trip.isActive && !trip.isUpcoming
                
                MapPolyline(coordinates: [trip.origin.clCoordinate, trip.destination.clCoordinate])
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
