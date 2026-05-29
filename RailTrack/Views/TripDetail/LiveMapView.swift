import SwiftUI
import MapKit

struct LiveMapView: View {
    let trip: Trip

    @State private var position: MapCameraPosition
    @State private var trainCoordinate: CLLocationCoordinate2D? = nil
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    init(trip: Trip) {
        self.trip = trip
        let midLat = (trip.origin.coordinate.latitude + trip.destination.coordinate.latitude) / 2
        let midLon = (trip.origin.coordinate.longitude + trip.destination.coordinate.longitude) / 2

        // Compute actual distance and add 50% padding; floor at 50 km for short hops
        let originLoc = CLLocation(latitude: trip.origin.coordinate.latitude, longitude: trip.origin.coordinate.longitude)
        let destLoc   = CLLocation(latitude: trip.destination.coordinate.latitude, longitude: trip.destination.coordinate.longitude)
        let span = max(originLoc.distance(from: destLoc) * 1.5, 50_000)

        _position = State(initialValue: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
                latitudinalMeters: span,
                longitudinalMeters: span
            )
        ))
    }

    var body: some View {
        Map(position: $position) {
            // Origin marker
            Annotation(trip.origin.shortName, coordinate: trip.origin.clCoordinate) {
                StationMarker(code: trip.origin.code, isOrigin: true)
            }

            // Destination marker
            Annotation(trip.destination.shortName, coordinate: trip.destination.clCoordinate) {
                StationMarker(code: trip.destination.code, isOrigin: false)
            }

            // Route polyline (straight line for now; replace with GTFS shape)
            MapPolyline(coordinates: [trip.origin.clCoordinate, trip.destination.clCoordinate])
                .stroke(ColorTheme.operatorColor(for: trip.trainOperator), lineWidth: 3)

            // Train position
            if let trainCoord = trainCoordinate {
                Annotation("Train \(trip.trainNumber)", coordinate: trainCoord) {
                    TrainPositionMarker(operatorColor: ColorTheme.operatorColor(for: trip.trainOperator))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            updateTrainCoordinate()
        }
        .onReceive(timer) { _ in
            updateTrainCoordinate()
        }
    }

    private func updateTrainCoordinate() {
        guard trip.isActive else {
            self.trainCoordinate = nil
            return
        }

        // Use live coordinates if available and fresh (updated within 5 minutes)
        if let liveLat = trip.liveLatitude,
           let liveLng = trip.liveLongitude,
           let liveUpd = trip.liveUpdated,
           Date().timeIntervalSince(liveUpd) < 300 {
            self.trainCoordinate = CLLocationCoordinate2D(latitude: liveLat, longitude: liveLng)
            return
        }

        let now = Date()
        let dep = trip.scheduledDeparture
        let arr = trip.scheduledArrival

        let total = arr.timeIntervalSince(dep)
        guard total > 0 else {
            self.trainCoordinate = nil
            return
        }

        let elapsed = now.timeIntervalSince(dep)
        let fraction = max(0, min(1, elapsed / total))

        self.trainCoordinate = interpolate(
            from: trip.origin.clCoordinate,
            to: trip.destination.clCoordinate,
            fraction: fraction
        )
    }


    private func interpolate(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: from.latitude + (to.latitude - from.latitude) * fraction,
            longitude: from.longitude + (to.longitude - from.longitude) * fraction
        )
    }
}

// MARK: - Markers

private struct StationMarker: View {
    let code: String
    let isOrigin: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(code)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(isOrigin ? Color.white.opacity(0.2) : Color.white.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.4), lineWidth: 1))

            Triangle()
                .fill(isOrigin ? Color.white.opacity(0.5) : Color.white.opacity(0.3))
                .frame(width: 8, height: 5)
        }
    }
}

private struct TrainPositionMarker: View {
    let operatorColor: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(operatorColor.opacity(0.25))
                .frame(width: 40, height: 40)
                .scaleEffect(pulse ? 1.4 : 1.0)
                .opacity(pulse ? 0 : 1)
                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)

            Circle()
                .fill(operatorColor)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "tram.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: operatorColor.opacity(0.6), radius: 6)
        }
        .onAppear { pulse = true }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

#Preview {
    LiveMapView(trip: MockDataService.shared.sampleTrips[0])
        .frame(height: 300)
}
