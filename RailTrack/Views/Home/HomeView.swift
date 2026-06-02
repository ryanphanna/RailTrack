import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripRecord.scheduledDeparture, order: .forward) private var records: [TripRecord]
    
    @State private var activePrepopulatedTrip: PrepopulatedTrip? = nil
    @State private var showSettings = false
    
    // Smart Search Query
    @State private var searchQuery = ""
    @FocusState private var isSearchFocused: Bool
    
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

    // MARK: - Parser helpers
    private struct ParsedRoute {
        let origin: Station
        let destination: Station
    }
    
    private func parseRouteQuery(_ query: String) -> ParsedRoute? {
        let clean = query.lowercased()
        let separators = [" to ", " -> ", " ->", "->", " - ", "-"]
        
        for sep in separators {
            if clean.contains(sep) {
                let parts = clean.components(separatedBy: sep)
                guard parts.count == 2 else { continue }
                let origPart = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let destPart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let origStation = StationDatabase.shared.search(origPart).first,
                   let destStation = StationDatabase.shared.search(destPart).first,
                   origStation.id != destStation.id {
                    return ParsedRoute(origin: origStation, destination: destStation)
                }
            }
        }
        return nil
    }
    
    private func parseTrainQuery(_ query: String) -> (number: String, op: String)? {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return nil }
        
        // Match operator prefix
        for op in ["via", "amtrak", "amt", "go"] {
            if clean.hasPrefix(op) {
                let num = clean.dropFirst(op.count).trimmingCharacters(in: .whitespacesAndNewlines)
                if !num.isEmpty {
                    return (number: num.uppercased(), op: op == "amt" ? "Amtrak" : op.uppercased())
                }
            }
        }
        
        // Pure number -> guess VIA Rail
        if let val = Int(clean) {
            return (number: "\(val)", op: "VIA")
        }
        
        return nil
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
                    Map(position: $appState.sharedCameraPosition) {
                        ForEach(records.map { $0.toTrip() }.filter { $0.isActive || $0.isUpcoming }) { trip in
                            Annotation(trip.origin.shortName, coordinate: trip.origin.clCoordinate) {
                                StationMarker(code: trip.origin.code, isOrigin: true)
                            }
                            
                            Annotation(trip.destination.shortName, coordinate: trip.destination.clCoordinate) {
                                StationMarker(code: trip.destination.code, isOrigin: false)
                            }
                            
                            MapPolyline(coordinates: [trip.origin.clCoordinate, trip.destination.clCoordinate])
                                .stroke(ColorTheme.operatorColor(for: trip.trainOperator), lineWidth: 3)
                            
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
                    
                    // Floating Settings & Locate Buttons in Top Right
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(ColorTheme.textSecondary)
                                        .padding(12)
                                        .background(ColorTheme.surface, in: Circle())
                                        .overlay(Circle().stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    withAnimation(.spring()) {
                                        updateMapPosition()
                                    }
                                } label: {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(ColorTheme.textSecondary)
                                        .padding(12)
                                        .background(ColorTheme.surface, in: Circle())
                                        .overlay(Circle().stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
                                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 60)
                            .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                    .ignoresSafeArea()
                    
                    // Scrim overlay
                    if drawerState == .expanded {
                        Color.black
                            .opacity(max(0, min(0.4, (currentHeight - peekHeight) / (expandedHeight - peekHeight) * 0.4)))
                            .ignoresSafeArea()
                            .onTapGesture {
                                isSearchFocused = false
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
                        
                        // Header Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(ColorTheme.textTertiary)
                            
                            TextField("Search train, station, or route…", text: $searchQuery, prompt: Text("Search train, station, or route…").foregroundColor(ColorTheme.textTertiary.opacity(0.6)))
                                .font(.rtBody.bold())
                                .foregroundStyle(ColorTheme.textPrimary)
                                .focused($isSearchFocused)
                                .autocorrectionDisabled()
                            
                            if !searchQuery.isEmpty {
                                Button {
                                    searchQuery = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(ColorTheme.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Scrollable Content: Lists or Smart Results
                        ScrollView {
                            if searchQuery.isEmpty {
                                // Default Journeys lists
                                VStack(spacing: 20) {
                                    ICloudBannerView()
                                    
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
                                    
                                    if records.isEmpty {
                                        EmptyTripsView()
                                            .padding(.top, 16)
                                    }
                                    
                                    Color.clear.frame(height: 100)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                            } else {
                                // Smart Search Results
                                VStack(spacing: 20) {
                                    let parsedTrain = parseTrainQuery(searchQuery)
                                    let parsedRoute = parseRouteQuery(searchQuery)
                                    let stationResults = StationDatabase.shared.search(searchQuery)
                                    
                                    // 1. Train lookup result
                                    if let train = parsedTrain {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("SCHEDULE LOOKUP")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(ColorTheme.textTertiary)
                                                .tracking(1)
                                                .padding(.horizontal, 4)
                                            
                                            Button {
                                                isSearchFocused = false
                                                activePrepopulatedTrip = PrepopulatedTrip(
                                                    origin: nil,
                                                    destination: nil,
                                                    trainNumber: train.number,
                                                    operatorName: train.op
                                                )
                                            } label: {
                                                HStack(spacing: 14) {
                                                    Image(systemName: "magnifyingglass.circle.fill")
                                                        .font(.system(size: 26))
                                                        .foregroundStyle(ColorTheme.operatorColor(for: train.op))
                                                    
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text("Look up Schedule for Train \(train.number)")
                                                            .font(.rtBody.bold())
                                                            .foregroundStyle(ColorTheme.textPrimary)
                                                        Text("Queries \(train.op) database for live departure/arrival times")
                                                            .font(.rtCaption)
                                                            .foregroundStyle(ColorTheme.textTertiary)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundStyle(ColorTheme.textTertiary)
                                                }
                                                .padding(16)
                                                .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(ColorTheme.operatorColor(for: train.op).opacity(0.15), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    
                                    // 2. Route parsed result
                                    if let route = parsedRoute {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("ROUTE MATCH")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(ColorTheme.textTertiary)
                                                .tracking(1)
                                                .padding(.horizontal, 4)
                                            
                                            Button {
                                                isSearchFocused = false
                                                activePrepopulatedTrip = PrepopulatedTrip(
                                                    origin: route.origin,
                                                    destination: route.destination,
                                                    trainNumber: "",
                                                    operatorName: route.origin.railOperator ?? "VIA"
                                                )
                                            } label: {
                                                HStack(spacing: 14) {
                                                    Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle.fill")
                                                        .font(.system(size: 26))
                                                        .foregroundStyle(ColorTheme.accent)
                                                    
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text("Add Trip: \(route.origin.shortName) ➔ \(route.destination.shortName)")
                                                            .font(.rtBody.bold())
                                                            .foregroundStyle(ColorTheme.textPrimary)
                                                        Text("Pre-populates origin and destination stations")
                                                            .font(.rtCaption)
                                                            .foregroundStyle(ColorTheme.textTertiary)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundStyle(ColorTheme.accent)
                                                        .padding(8)
                                                        .background(ColorTheme.accent.opacity(0.12), in: Circle())
                                                }
                                                .padding(16)
                                                .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(ColorTheme.accent.opacity(0.15), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    
                                    // 3. Station search results
                                    if !stationResults.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("STATIONS")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(ColorTheme.textTertiary)
                                                .tracking(1)
                                                .padding(.horizontal, 4)
                                            
                                            VStack(spacing: 0) {
                                                ForEach(stationResults.prefix(4)) { station in
                                                    Menu {
                                                        Button {
                                                            isSearchFocused = false
                                                            activePrepopulatedTrip = PrepopulatedTrip(
                                                                origin: station,
                                                                destination: nil,
                                                                trainNumber: "",
                                                                operatorName: station.railOperator ?? "VIA"
                                                            )
                                                        } label: {
                                                            Label("Set as Departure", systemImage: "arrow.up.right.circle")
                                                        }
                                                        
                                                        Button {
                                                            isSearchFocused = false
                                                            activePrepopulatedTrip = PrepopulatedTrip(
                                                                origin: nil,
                                                                destination: station,
                                                                trainNumber: "",
                                                                operatorName: station.railOperator ?? "VIA"
                                                            )
                                                        } label: {
                                                            Label("Set as Arrival", systemImage: "arrow.down.left.circle")
                                                        }
                                                    } label: {
                                                        HStack(spacing: 12) {
                                                            Text(station.code)
                                                                .font(.rtMono)
                                                                .foregroundStyle(ColorTheme.operatorColor(for: station.railOperator ?? ""))
                                                                .frame(width: 36)
                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text(station.name)
                                                                    .font(.rtBody.bold())
                                                                    .foregroundStyle(ColorTheme.textPrimary)
                                                                Text("\(station.city) • \(station.railOperator ?? "Other")")
                                                                    .font(.rtCaption)
                                                                    .foregroundStyle(ColorTheme.textTertiary)
                                                            }
                                                            Spacer()
                                                            Image(systemName: "plus.circle.fill")
                                                                    .font(.system(size: 16))
                                                                    .foregroundStyle(ColorTheme.textTertiary.opacity(0.7))
                                                        }
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 12)
                                                        .contentShape(Rectangle())
                                                    }
                                                    .buttonStyle(.plain)
                                                    
                                                    if station.id != stationResults.prefix(4).last?.id {
                                                        Divider().padding(.leading, 64).opacity(0.08)
                                                    }
                                                }
                                            }
                                            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(ColorTheme.textTertiary.opacity(0.12), lineWidth: 1)
                                            )
                                        }
                                    }
                                    
                                    // 4. Manual Add fallback
                                    Button {
                                        isSearchFocused = false
                                        activePrepopulatedTrip = PrepopulatedTrip(
                                            origin: nil,
                                            destination: nil,
                                            trainNumber: "",
                                            operatorName: "VIA"
                                        )
                                    } label: {
                                        Text("Add Trip Manually")
                                            .font(.rtSubhead.bold())
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(ColorTheme.surfaceHigh, in: RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 10)
                                    
                                    Color.clear.frame(height: 100)
                                }
                                .padding(.horizontal, 20)
                            }
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
                    .ignoresSafeArea(edges: .bottom)
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
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $activePrepopulatedTrip) { trip in
                AddTripView(
                    initialOrigin: trip.origin,
                    initialDestination: trip.destination,
                    initialTrainNumber: trip.trainNumber,
                    initialOperator: trip.operatorName
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                if !appState.hasInitializedCameraPosition {
                    updateMapPosition()
                    appState.hasInitializedCameraPosition = true
                }
                LiveActivityManager.shared.syncActiveTrip(activeRecord?.toTrip())
            }
            .onChange(of: isSearchFocused) { _, isFocused in
                if isFocused {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        drawerState = .expanded
                    }
                }
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
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 42.8, longitude: -77.2),
                span: MKCoordinateSpan(latitudeDelta: 7.0, longitudeDelta: 8.0)
            )
            appState.sharedCameraPosition = .region(region)
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
        
        let latDelta = max(1.2, (maxLat - minLat) * 1.4)
        let lonDelta = max(1.2, (maxLon - minLon) * 1.4)
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
        appState.sharedCameraPosition = .region(region)
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
            Text("Use the search bar above to look up schedules or add a station route.")
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
