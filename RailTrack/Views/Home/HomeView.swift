import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripRecord.scheduledDeparture, order: .forward) private var records: [TripRecord]
    @State private var showAddTrip = false
    @State private var showSettings = false
    
    // Map camera position
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // Bottom drawer state
    enum DrawerState {
        case peek
        case expanded
    }
    @State private var drawerState: DrawerState = .peek
    @State private var dragOffset: CGFloat = 0
    
    private let liveActivityTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    // MARK: - Filtered sections
    private var activeRecord: TripRecord? {
        records.first(where: { $0.toTrip().isActive })
    }
    private var upcomingRecords: [TripRecord] {
        records.filter { $0.toTrip().isUpcoming }
    }
    private var pastRecords: [TripRecord] {
        Array(records.filter {
            let t = $0.toTrip(); return !t.isActive && !t.isUpcoming
        }.reversed())
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let screenHeight = geo.size.height
                let peekHeight: CGFloat = 260
                let expandedHeight: CGFloat = screenHeight - 60
                
                let currentHeight = max(peekHeight, (drawerState == .expanded ? expandedHeight : peekHeight) - dragOffset)
                
                ZStack(alignment: .bottom) {
                    // 1. Background Interactive Map
                    Map(position: $cameraPosition) {
                        ForEach(records.map { $0.toTrip() }.filter { $0.isActive || $0.isUpcoming }) { trip in
                            // Origin station marker
                            Annotation(trip.origin.shortName, coordinate: trip.origin.clCoordinate) {
                                StationMarker(code: trip.origin.code, isOrigin: true)
                            }
                            
                            // Destination station marker
                            Annotation(trip.destination.shortName, coordinate: trip.destination.clCoordinate) {
                                StationMarker(code: trip.destination.code, isOrigin: false)
                            }
                            
                            // Polyline track
                            MapPolyline(coordinates: [trip.origin.clCoordinate, trip.destination.clCoordinate])
                                .stroke(ColorTheme.operatorColor(for: trip.trainOperator), lineWidth: 3)
                            
                            // Live train position (interpolated or GPS)
                            if trip.isActive, let trainCoord = getInterpolatedCoordinate(for: trip) {
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
                    .ignoresSafeArea(edges: .all)
                    
                    // Transparent scrim when drawer is expanded to focus on list
                    if drawerState == .expanded {
                        Color.black
                            .opacity(max(0, min(0.4, (currentHeight - peekHeight) / (expandedHeight - peekHeight) * 0.4)))
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    drawerState = .peek
                                }
                            }
                    }
                    
                    // 2. Sliding Drawer Panel
                    VStack(spacing: 0) {
                        // Drag handle
                        Capsule()
                            .fill(ColorTheme.textTertiary.opacity(0.35))
                            .frame(width: 38, height: 5)
                            .padding(.top, 10)
                            .padding(.bottom, 12)
                        
                        // Header section inside drawer
                        HStack {
                            Text("RailTrack")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(ColorTheme.textPrimary)
                            
                            Spacer()
                            
                            // Settings gear
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(ColorTheme.textSecondary)
                                    .padding(9)
                                    .background(ColorTheme.surfaceHigh, in: Circle())
                            }
                            .buttonStyle(.plain)
                            
                            // Add trip plus
                            Button {
                                showAddTrip = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(9)
                                    .background(ColorTheme.accent, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                        
                        // Scrollable trip list content
                        ScrollView {
                            VStack(spacing: 20) {
                                ICloudBannerView()
                                
                                // Active trip section
                                if let rec = activeRecord {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "tram.fill")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(ColorTheme.accentGreen)
                                            Text("NOW BOARDING")
                                                .font(.rtCaption.bold())
                                                .foregroundStyle(ColorTheme.textSecondary)
                                                .tracking(0.6)
                                        }
                                        .padding(.horizontal, 4)
                                        
                                        NavigationLink(destination: TripDetailView(record: rec)) {
                                            TripCardView(trip: rec.toTrip())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                // Upcoming section
                                if !upcomingRecords.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(ColorTheme.accent)
                                            Text("UPCOMING")
                                                .font(.rtCaption.bold())
                                                .foregroundStyle(ColorTheme.textSecondary)
                                                .tracking(0.6)
                                        }
                                        .padding(.horizontal, 4)
                                        
                                        ForEach(upcomingRecords) { rec in
                                            NavigationLink(destination: TripDetailView(record: rec)) {
                                                TripCardView(trip: rec.toTrip())
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    deleteTrip(id: rec.id)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Past section
                                if !pastRecords.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(ColorTheme.textTertiary)
                                            Text("PAST JOURNEYS")
                                                .font(.rtCaption.bold())
                                                .foregroundStyle(ColorTheme.textSecondary)
                                                .tracking(0.6)
                                        }
                                        .padding(.horizontal, 4)
                                        
                                        ForEach(pastRecords) { rec in
                                            NavigationLink(destination: TripDetailView(record: rec)) {
                                                TripCardView(trip: rec.toTrip())
                                                    .opacity(0.65)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    deleteTrip(id: rec.id)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Empty state
                                if records.isEmpty {
                                    EmptyTripsView()
                                        .padding(.top, 16)
                                }
                                
                                Color.clear.frame(height: 100)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }
                        .scrollDisabled(drawerState == .peek)
                    }
                    .frame(height: currentHeight)
                    .frame(maxWidth: .infinity)
                    .background(
                        ColorTheme.background
                            .shadow(color: Color.black.opacity(0.35), radius: 12, y: -4)
                    )
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.height
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 60
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    if value.translation.height < -threshold {
                                        drawerState = .expanded
                                    } else if value.translation.height > threshold {
                                        drawerState = .peek
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar) // Hide standard nav bar to let the map take center stage
            .sheet(isPresented: $showAddTrip) {
                AddTripView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                updateMapPosition()
                LiveActivityManager.shared.syncActiveTrip(activeRecord?.toTrip())
            }
            .onReceive(liveActivityTimer) { _ in
                LiveActivityManager.shared.syncActiveTrip(activeRecord?.toTrip())
            }
            .onChange(of: records) { _, newValue in
                updateMapPosition()
                let activeTrip = newValue.first(where: { $0.toTrip().isActive })?.toTrip()
                LiveActivityManager.shared.syncActiveTrip(activeTrip)
            }
        }
    }

    // MARK: - Helper Methods

    private func deleteTrip(id: UUID) {
        if let record = records.first(where: { $0.id == id }) {
            NotificationService.shared.cancelNotifications(for: record.toTrip())
            modelContext.delete(record)
        }
    }
    
    private func getInterpolatedCoordinate(for trip: Trip) -> CLLocationCoordinate2D? {
        guard trip.isActive else { return nil }
        
        if let liveLat = trip.liveLatitude,
           let liveLng = trip.liveLongitude,
           let liveUpd = trip.liveUpdated,
           Date().timeIntervalSince(liveUpd) < 300 {
            return CLLocationCoordinate2D(latitude: liveLat, longitude: liveLng)
        }
        
        let now = Date()
        let dep = trip.scheduledDeparture
        let arr = trip.scheduledArrival
        
        let total = arr.timeIntervalSince(dep)
        guard total > 0 else { return nil }
        
        let elapsed = now.timeIntervalSince(dep)
        let fraction = max(0, min(1, elapsed / total))
        
        return CLLocationCoordinate2D(
            latitude: trip.origin.clCoordinate.latitude + (trip.destination.clCoordinate.latitude - trip.origin.clCoordinate.latitude) * fraction,
            longitude: trip.origin.clCoordinate.longitude + (trip.destination.clCoordinate.longitude - trip.origin.clCoordinate.longitude) * fraction
        )
    }
    
    private func updateMapPosition() {
        let activeOrUpcoming = records.map { $0.toTrip() }.filter { $0.isActive || $0.isUpcoming }
        
        if activeOrUpcoming.isEmpty {
            // Default region: Northeast Corridor (covers Toronto, Montreal, New York)
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 42.8, longitude: -77.2),
                span: MKCoordinateSpan(latitudeDelta: 7.0, longitudeDelta: 8.0)
            )
            cameraPosition = .region(region)
            return
        }
        
        var coords: [CLLocationCoordinate2D] = []
        for trip in activeOrUpcoming {
            coords.append(trip.origin.clCoordinate)
            coords.append(trip.destination.clCoordinate)
        }
        
        let minLat = coords.map { $0.latitude }.min() ?? 43.6453
        let maxLat = coords.map { $0.latitude }.max() ?? 43.6453
        let minLon = coords.map { $0.longitude }.min() ?? -79.3806
        let maxLon = coords.map { $0.longitude }.max() ?? -79.3806
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Add 40% padding so markers aren't right at the screen edge
        let latDelta = max(1.2, (maxLat - minLat) * 1.4)
        let lonDelta = max(1.2, (maxLon - minLon) * 1.4)
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
        cameraPosition = .region(region)
    }
}

// MARK: - Corner Radius Helpers

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(shapeCornerRadius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var shapeCornerRadius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: shapeCornerRadius, height: shapeCornerRadius))
        return Path(path.cgPath)
    }
}

// MARK: - Empty State

private struct EmptyTripsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.system(size: 52))
                .foregroundStyle(ColorTheme.textTertiary)
            Text("No trips yet")
                .font(.rtHeadline)
                .foregroundStyle(ColorTheme.textPrimary)
            Text("Tap + to add your first train journey.")
                .font(.rtBody)
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .modelContainer(for: TripRecord.self, inMemory: true)
}
