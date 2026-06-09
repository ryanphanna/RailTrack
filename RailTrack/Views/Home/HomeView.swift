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

    @StateObject private var proximityManager = StationProximityManager.shared
    
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
    struct ParsedRoute {
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
                    homeMap
                    floatingControls
                    scrim(currentHeight: currentHeight, peekHeight: peekHeight, expandedHeight: expandedHeight)
                    drawer(currentHeight: currentHeight)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .task {
                await ScheduleUpdateService.shared.refreshUpcomingTrips(modelContext: modelContext)
            }
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
            .onReceive(liveActivityTimer) { _ in
                // Periodically update UI/Map if an activity is live
            }
            .onChange(of: records) { _, newValue in
                if !appState.hasInitializedCameraPosition {
                    withAnimation(.spring()) {
                        updateMapPosition()
                    }
                    appState.hasInitializedCameraPosition = true
                }
            }
            .onAppear {
                if !appState.hasInitializedCameraPosition {
                    updateMapPosition()
                    appState.hasInitializedCameraPosition = true
                }
            }
        }
    }

    private var homeMap: some View {
        HomeMapView(
            records: records,
            position: $appState.sharedCameraPosition,
            getInterpolatedCoordinate: getInterpolatedCoordinate
        )
        .ignoresSafeArea(edges: .all)
    }

    private var floatingControls: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    circleButton(systemName: "gearshape.fill") {
                        showSettings = true
                    }

                    circleButton(systemName: "location.fill") {
                        withAnimation(.spring()) {
                            updateMapPosition()
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.trailing, 20)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ColorTheme.textSecondary)
                .padding(12)
                .background(ColorTheme.surface, in: Circle())
                .overlay(Circle().stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func scrim(currentHeight: CGFloat, peekHeight: CGFloat, expandedHeight: CGFloat) -> some View {
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
    }

    private func drawer(currentHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(ColorTheme.textTertiary.opacity(0.35))
                .frame(width: 38, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 12)

            searchBar
            drawerScrollContent
        }
        .frame(height: currentHeight)
        .frame(maxWidth: .infinity)
        .background(
            ColorTheme.background
                .shadow(color: Color.black.opacity(0.35), radius: 12, y: -4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
        .gesture(drawerDragGesture)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ColorTheme.textTertiary)

            TextField("Search train, station, or route...", text: $searchQuery, prompt: Text("Search train, station, or route...").foregroundColor(ColorTheme.textTertiary.opacity(0.6)))
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
    }

    private var drawerScrollContent: some View {
        ScrollView {
            if searchQuery.isEmpty {
                defaultJourneyList
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            } else {
                HomeSmartSearchView(
                    searchQuery: searchQuery,
                    isSearchFocused: $isSearchFocused,
                    activePrepopulatedTrip: $activePrepopulatedTrip,
                    parseTrainQuery: parseTrainQuery,
                    parseRouteQuery: parseRouteQuery
                )
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }

    private var defaultJourneyList: some View {
        VStack(spacing: 20) {
            ICloudBannerView()
            activeJourneySection
            upcomingJourneySection
            pastJourneySection

            if records.isEmpty {
                EmptyTripsView()
                    .padding(.top, 16)
            }

            Color.clear.frame(height: 100)
        }
    }

    @ViewBuilder
    private var activeJourneySection: some View {
        if let rec = activeRecord {
            let trip = rec.toTrip()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    sectionHeader(systemName: "tram.fill", title: "NOW BOARDING", color: ColorTheme.accentGreen)
                    Spacer()
                    if proximityManager.isAtDestination {
                        Text("ARRIVED AT \(trip.destination.code)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(ColorTheme.accentGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ColorTheme.accentGreen.opacity(0.1), in: Capsule())
                    }
                }

                NavigationLink(destination: TripDetailView(record: rec)) {
                    TripCardView(trip: trip)
                }
                .buttonStyle(.plain)
            }
            .onAppear {
                if let loc = LocationManager.shared.location {
                    proximityManager.updateProximity(for: trip, at: loc)
                }
                proximityManager.activeTrip = trip
            }
            .onDisappear {
                proximityManager.activeTrip = nil
            }
        }
    }

    @ViewBuilder
    private var upcomingJourneySection: some View {
        if !upcomingRecords.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(systemName: "calendar", title: "UPCOMING", color: ColorTheme.accent)
                recordLinks(upcomingRecords)
            }
        }
    }

    @ViewBuilder
    private var pastJourneySection: some View {
        if !pastRecords.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(systemName: "clock.fill", title: "PAST JOURNEYS", color: ColorTheme.textTertiary)
                recordLinks(pastRecords)
            }
        }
    }

    private func sectionHeader(systemName: String, title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.rtCaption.bold())
                .foregroundStyle(ColorTheme.textSecondary)
                .tracking(0.6)
        }
        .padding(.horizontal, 4)
    }

    private func recordLinks(_ records: [TripRecord]) -> some View {
        ForEach(records) { rec in
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

    private var drawerDragGesture: some Gesture {
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
    }
    
    // MARK: - Actions & Logic
    
    private func deleteTrip(id: UUID) {
        if let record = records.first(where: { $0.id == id }) {
            modelContext.delete(record)
            try? modelContext.save()
        }
    }
    
    private func getInterpolatedCoordinate(for trip: Trip) -> CLLocationCoordinate2D? {
        guard trip.isActive else { return nil }
        
        let now = Date()
        let total = trip.scheduledArrival.timeIntervalSince(trip.scheduledDeparture)
        let elapsed = now.timeIntervalSince(trip.scheduledDeparture)
        
        let fraction = max(0, min(1, elapsed / total))
        
        guard total > 0 else { return nil }
        
        let from = trip.origin.clCoordinate
        let to = trip.destination.clCoordinate
        
        return CLLocationCoordinate2D(
            latitude: from.latitude + (to.latitude - from.latitude) * fraction,
            longitude: from.longitude + (to.longitude - from.longitude) * fraction
        )
    }

    private func updateMapPosition() {
        let activeOrUpcoming = records.map { $0.toTrip() }.filter { $0.isActive || $0.isUpcoming }
        guard !activeOrUpcoming.isEmpty else {
            // Default to whole of North America if no trips
            appState.sharedCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.0, longitude: -80.0),
                latitudinalMeters: 2_000_000,
                longitudinalMeters: 2_000_000
            ))
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
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5 + 0.5, longitudeDelta: (maxLon - minLon) * 1.5 + 0.5)
        
        appState.sharedCameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .modelContainer(for: TripRecord.self, inMemory: true)
}
