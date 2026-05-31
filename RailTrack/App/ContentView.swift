import SwiftUI
import CoreLocation
import MapKit
import Combine

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !appState.isOnboarded {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .task {
            // Initial sync on app load
            await VIALiveDataService.shared.fetchAndSync(modelContext: modelContext)
            await AmtrakLiveDataService.shared.fetchAndSync(modelContext: modelContext)
            await GOLiveDataService.shared.fetchAndSync(modelContext: modelContext)
            
            // Periodically sync every 30 seconds
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                await VIALiveDataService.shared.fetchAndSync(modelContext: modelContext)
                await AmtrakLiveDataService.shared.fetchAndSync(modelContext: modelContext)
                await GOLiveDataService.shared.fetchAndSync(modelContext: modelContext)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await VIALiveDataService.shared.fetchAndSync(modelContext: modelContext)
                    await AmtrakLiveDataService.shared.fetchAndSync(modelContext: modelContext)
                    await GOLiveDataService.shared.fetchAndSync(modelContext: modelContext)
                }
            }
        }
    }
}


struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, explore, stats, social
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Trips", systemImage: "tram.fill")
                }
                .tag(Tab.home)

            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "safari.fill")
                }
                .tag(Tab.explore)

            StatsView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.stats)

            SocialView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(Tab.social)
        }
        .tint(ColorTheme.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

// MARK: - Location Manager

/// A thread-safe, SwiftUI-friendly helper to manage device location updates.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 500 // Update location only if moved 500m
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            } else {
                manager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.location = latest
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Failed to fetch location: \(error.localizedDescription)")
    }
}

// MARK: - Explore View

struct ExploreView: View {
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedTab: ExploreTab = .map
    @State private var amtrakTrains: [AmtrakLiveDataService.AmtrakTrain] = []
    @State private var viaTrains: [String: VIALiveDataService.VIALiveTrain] = [:]
    @State private var goTrains: [String: GOLiveDataService.GOLiveTrain] = [:]
    
    @State private var isLoading = false
    @State private var selectedPrepopulatedTrip: PrepopulatedTrip? = nil
    
    // Nearest station state
    @State private var nearbyDepartures: [NearbyDeparture] = []
    @State private var closestStationName: String = ""
    
    enum ExploreTab: String, CaseIterable, Identifiable {
        case map = "Map"
        case board = "Station Board"
        case active = "Active Trains"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .map: return "map.fill"
            case .board: return "tablecells.fill"
            case .active: return "tram.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Explore")
                                .font(.rtTitle)
                                .foregroundStyle(ColorTheme.textPrimary)
                            
                            if !closestStationName.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(ColorTheme.accent)
                                    Text("Near \(closestStationName)")
                                        .font(.rtCaption)
                                        .foregroundStyle(ColorTheme.textSecondary)
                                }
                            } else if locationManager.authorizationStatus == .notDetermined {
                                Button {
                                    locationManager.requestPermission()
                                } label: {
                                    Text("Enable Location Access")
                                        .font(.rtCaption.bold())
                                        .foregroundStyle(ColorTheme.accent)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("Select a station or view map below")
                                    .font(.rtCaption)
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                        }
                        
                        Spacer()
                        
                        // Pull to refresh / Loading indicator
                        Button {
                            Task {
                                await refreshFeeds()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(ColorTheme.accent)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(ColorTheme.textSecondary)
                                    .padding(8)
                                    .background(ColorTheme.surface, in: Circle())
                                    .overlay(Circle().stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
                            }
                        }
                        .disabled(isLoading)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
                    
                    // Departing Soon Nearby Section (Only shown if we have departures)
                    if !nearbyDepartures.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("DEPARTING SOON NEARBY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ColorTheme.textTertiary)
                                    .tracking(1.2)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(nearbyDepartures.prefix(5)) { departure in
                                        Button {
                                            selectedPrepopulatedTrip = PrepopulatedTrip(
                                                origin: departure.station,
                                                destination: nil,
                                                trainNumber: departure.trainNumber,
                                                operatorName: departure.operatorName
                                            )
                                        } label: {
                                            NearbyDepartureCard(departure: departure)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 6)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.bottom, 16)
                    }
                    
                    // Tab segmented selector
                    HStack(spacing: 6) {
                        ForEach(ExploreTab.allCases) { tab in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                    selectedTab = tab
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 12, weight: .bold))
                                    Text(tab.rawValue)
                                        .font(.rtSubhead.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == tab ? ColorTheme.surfaceHigh : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(selectedTab == tab ? ColorTheme.textPrimary : ColorTheme.textSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedTab == tab ? ColorTheme.textTertiary.opacity(0.18) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    
                    // Selected View Content
                    ZStack {
                        switch selectedTab {
                        case .map:
                            LiveExploreMapView(
                                amtrakTrains: amtrakTrains,
                                viaTrains: viaTrains,
                                goTrains: goTrains,
                                selectedPrepopulatedTrip: $selectedPrepopulatedTrip
                            )
                        case .board:
                            StationBoardView(
                                amtrakTrains: amtrakTrains,
                                viaTrains: viaTrains,
                                goTrains: goTrains,
                                selectedPrepopulatedTrip: $selectedPrepopulatedTrip
                            )
                        case .active:
                            ActiveTrainsListView(
                                amtrakTrains: amtrakTrains,
                                viaTrains: viaTrains,
                                goTrains: goTrains,
                                selectedPrepopulatedTrip: $selectedPrepopulatedTrip
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .task {
                await refreshFeeds()
                locationManager.requestPermission()
                locationManager.startUpdating()
            }
            .onDisappear {
                locationManager.stopUpdating()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                if let location = newLocation {
                    updateNearbyDepartures(for: location)
                }
            }
            .sheet(item: $selectedPrepopulatedTrip) { trip in
                AddTripView(
                    initialOrigin: trip.origin,
                    initialDestination: trip.destination,
                    initialTrainNumber: trip.trainNumber,
                    initialOperator: trip.operatorName
                )
            }
        }
    }
    
    // MARK: - Actions & Logic
    
    private func refreshFeeds() async {
        guard !isLoading else { return }
        isLoading = true
        
        async let amtrakTask = AmtrakLiveDataService.shared.getActiveTrains()
        async let viaTask = VIALiveDataService.shared.getActiveTrains()
        async let goTask = GOLiveDataService.shared.getActiveTrains()
        
        let (amtrak, via, go) = await (amtrakTask, viaTask, goTask)
        
        self.amtrakTrains = amtrak
        self.viaTrains = via
        self.goTrains = go
        
        self.isLoading = false
        
        if let location = locationManager.location {
            updateNearbyDepartures(for: location)
        } else {
            // Default: use Toronto Union coords (43.6453, -79.3806) if permission not yet granted
            let fallbackLocation = CLLocation(latitude: 43.6453, longitude: -79.3806)
            updateNearbyDepartures(for: fallbackLocation)
        }
    }
    
    private func updateNearbyDepartures(for userLocation: CLLocation) {
        let stations = StationDatabase.shared.stations
        let sortedStations = stations.map { station -> (station: Station, distance: CLLocationDistance) in
            let stationLoc = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
            return (station, stationLoc.distance(from: userLocation))
        }
        .sorted(by: { $0.distance < $1.distance })
        
        guard let closest = sortedStations.first, closest.distance < 75000 else {
            self.nearbyDepartures = []
            self.closestStationName = ""
            return
        }
        
        self.closestStationName = closest.station.shortName
        
        let departures = getDepartures(for: closest.station, amtrakTrains: amtrakTrains, viaTrains: viaTrains, goTrains: goTrains)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.nearbyDepartures = departures
        }
    }
    
    private func getDepartures(
        for station: Station,
        amtrakTrains: [AmtrakLiveDataService.AmtrakTrain],
        viaTrains: [String: VIALiveDataService.VIALiveTrain],
        goTrains: [String: GOLiveDataService.GOLiveTrain]
    ) -> [NearbyDeparture] {
        var departures: [NearbyDeparture] = []
        let now = Date()
        
        // 1. Amtrak
        for train in amtrakTrains {
            if let stopIndex = train.stations.firstIndex(where: { $0.code == station.code }),
               let stop = train.stations[safe: stopIndex] {
                if stop.status != "Departed" {
                    if let schDepStr = stop.schDep, let schDepDate = AmtrakLiveDataService.shared.parseISO8601Date(schDepStr) {
                        if schDepDate.timeIntervalSince(now) > -1800 && schDepDate.timeIntervalSince(now) < 14400 {
                            let estDepDate = AmtrakLiveDataService.shared.parseISO8601Date(stop.dep)
                            let destinationCode = train.stations.last?.code ?? ""
                            let destinationName = StationDatabase.shared.stations.first(where: { $0.code == destinationCode })?.shortName ?? train.stations.last?.name ?? "Destination"
                            
                            var delay = 0
                            if let est = estDepDate {
                                delay = max(0, Int(est.timeIntervalSince(schDepDate) / 60))
                            }
                            
                            departures.append(NearbyDeparture(
                                trainNumber: train.trainNum,
                                operatorName: "Amtrak",
                                destinationName: destinationName,
                                scheduledDeparture: schDepDate,
                                estimatedDeparture: estDepDate,
                                delayMinutes: delay,
                                platform: stop.platform,
                                station: station,
                                originalTrainData: train
                            ))
                        }
                    }
                }
            }
        }
        
        // 2. VIA Rail
        for (key, train) in viaTrains {
            let trainNum = key.split(separator: " ").first.map(String.init) ?? key
            if let stopIndex = train.times.firstIndex(where: { $0.code == station.code }),
               let stop = train.times[safe: stopIndex] {
                if stopIndex < train.times.count - 1 {
                    if let schDepStr = stop.departure?.scheduled ?? stop.scheduled,
                       let schDepDate = VIALiveDataService.shared.parseISO8601Date(schDepStr) {
                        if schDepDate.timeIntervalSince(now) > -1800 && schDepDate.timeIntervalSince(now) < 14400 {
                            let estDepDate = VIALiveDataService.shared.parseISO8601Date(stop.departure?.estimated ?? stop.estimated ?? stop.eta)
                            let destinationCode = train.times.last?.code ?? ""
                            let destinationName = StationDatabase.shared.stations.first(where: { $0.code == destinationCode })?.shortName ?? train.times.last?.station ?? "Destination"
                            let delay = max(0, stop.diffMin ?? 0)
                            
                            departures.append(NearbyDeparture(
                                trainNumber: trainNum,
                                operatorName: "VIA",
                                destinationName: destinationName,
                                scheduledDeparture: schDepDate,
                                estimatedDeparture: estDepDate,
                                delayMinutes: delay,
                                platform: nil,
                                station: station,
                                originalTrainData: train
                            ))
                        }
                    }
                }
            }
        }
        
        // 3. GO Transit
        for (key, train) in goTrains {
            let trainNum = key.split(separator: " ").first.map(String.init) ?? key
            if let stopIndex = train.times.firstIndex(where: { $0.code == station.code }),
               let stop = train.times[safe: stopIndex] {
                if stopIndex < train.times.count - 1 {
                    if let schDepStr = stop.departure?.scheduled ?? stop.scheduled,
                       let schDepDate = GOLiveDataService.shared.parseISO8601Date(schDepStr) {
                        if schDepDate.timeIntervalSince(now) > -1800 && schDepDate.timeIntervalSince(now) < 14400 {
                            let estDepDate = GOLiveDataService.shared.parseISO8601Date(stop.departure?.estimated ?? stop.estimated ?? stop.eta)
                            let destinationCode = train.times.last?.code ?? ""
                            let destinationName = StationDatabase.shared.stations.first(where: { $0.code == destinationCode })?.shortName ?? train.times.last?.station ?? "Destination"
                            let delay = max(0, stop.diffMin ?? 0)
                            
                            departures.append(NearbyDeparture(
                                trainNumber: trainNum,
                                operatorName: "GO",
                                destinationName: destinationName,
                                scheduledDeparture: schDepDate,
                                estimatedDeparture: estDepDate,
                                delayMinutes: delay,
                                platform: nil,
                                station: station,
                                originalTrainData: train
                            ))
                        }
                    }
                }
            }
        }
        
        return departures.sorted(by: { $0.scheduledDeparture < $1.scheduledDeparture })
    }
}

// MARK: - Submodels

struct NearbyDeparture: Identifiable {
    let id = UUID()
    let trainNumber: String
    let operatorName: String
    let destinationName: String
    let scheduledDeparture: Date
    let estimatedDeparture: Date?
    let delayMinutes: Int
    let platform: String?
    let station: Station
    let originalTrainData: Any
}

// MARK: - Subviews

struct NearbyDepartureCard: View {
    let departure: NearbyDeparture
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Train \(departure.trainNumber)")
                        .font(.rtHeadline)
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    Text(departure.operatorName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ColorTheme.operatorColor(for: departure.operatorName), in: RoundedRectangle(cornerRadius: 4))
                }
                
                Spacer()
                
                let minutesRemaining = Int(departure.scheduledDeparture.timeIntervalSince(Date()) / 60)
                Text(minutesRemaining > 0 ? "in \(minutesRemaining)m" : "now")
                    .font(.rtMono)
                    .foregroundStyle(departure.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (departure.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
            }
            
            HStack(spacing: 4) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(ColorTheme.textTertiary)
                Text(departure.destinationName)
                    .font(.rtBody.bold())
                    .foregroundStyle(ColorTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Divider().opacity(0.08)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEPARTS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(0.5)
                    
                    Text(departure.scheduledDeparture.formatted(date: .omitted, time: .shortened))
                        .font(.rtMono.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                if departure.delayMinutes > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DELAY")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(ColorTheme.textTertiary)
                            .tracking(0.5)
                        
                        Text("+\(departure.delayMinutes) min")
                            .font(.rtMono.bold())
                            .foregroundStyle(ColorTheme.accentAmber)
                    }
                } else if let platform = departure.platform, !platform.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PLATFORM")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(ColorTheme.textTertiary)
                            .tracking(0.5)
                        
                        Text(platform)
                            .font(.rtMono.bold())
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 195)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.operatorColor(for: departure.operatorName).opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Live Explore Map View

struct LiveExploreMapView: View {
    let amtrakTrains: [AmtrakLiveDataService.AmtrakTrain]
    let viaTrains: [String: VIALiveDataService.VIALiveTrain]
    let goTrains: [String: GOLiveDataService.GOLiveTrain]
    
    @Binding var selectedPrepopulatedTrip: PrepopulatedTrip?
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.8, longitude: -77.5),
            span: MKCoordinateSpan(latitudeDelta: 6.0, longitudeDelta: 7.0)
        )
    )
    
    @State private var selectedTrain: SelectedTrainInfo? = nil
    
    struct SelectedTrainInfo: Identifiable, Equatable {
        var id: String { "\(operatorName)-\(trainNumber)" }
        let trainNumber: String
        let operatorName: String
        let originCode: String
        let originName: String
        let destCode: String
        let destName: String
        let speed: Int?
        let delayMinutes: Int
        let lat: Double
        let lon: Double
        
        static func == (lhs: SelectedTrainInfo, rhs: SelectedTrainInfo) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(amtrakTrains, id: \.trainID) { train in
                    if let lat = train.lat, let lon = train.lon {
                        Annotation("Amtrak \(train.trainNum)", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Button {
                                selectAmtrakTrain(train)
                            } label: {
                                TrainPositionMarker(operatorColor: ColorTheme.amtrak)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                ForEach(Array(viaTrains.keys), id: \.self) { key in
                    if let train = viaTrains[key], let lat = train.lat, let lon = train.lng {
                        let trainNum = key.split(separator: " ").first.map(String.init) ?? key
                        Annotation("VIA \(trainNum)", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Button {
                                selectViaTrain(number: trainNum, train: train)
                            } label: {
                                TrainPositionMarker(operatorColor: ColorTheme.via)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                ForEach(Array(goTrains.keys), id: \.self) { key in
                    if let train = goTrains[key], let lat = train.lat, let lon = train.lng {
                        let trainNum = key.split(separator: " ").first.map(String.init) ?? key
                        Annotation("GO \(trainNum)", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Button {
                                selectGoTrain(number: trainNum, train: train)
                            } label: {
                                TrainPositionMarker(operatorColor: ColorTheme.go)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            
            if let info = selectedTrain {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedTrain = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(ColorTheme.textTertiary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 6)
                    
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Train \(info.trainNumber)")
                                .font(.rtHeadline)
                                .foregroundStyle(ColorTheme.textPrimary)
                            
                            Text(info.operatorName)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ColorTheme.operatorColor(for: info.operatorName), in: RoundedRectangle(cornerRadius: 4))
                            
                            Spacer().frame(height: 8)
                            
                            if let speed = info.speed, speed > 0 {
                                Text("\(speed) \(info.operatorName == "Amtrak" ? "mph" : "km/h")")
                                    .font(.rtMono.bold())
                                    .foregroundStyle(ColorTheme.accentGreen)
                            } else {
                                Text("Stationary")
                                    .font(.rtCaption.bold())
                                    .foregroundStyle(ColorTheme.textSecondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(info.originCode)
                                    .font(.rtMono.bold())
                                    .foregroundStyle(ColorTheme.textPrimary)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ColorTheme.textTertiary)
                                Text(info.destCode)
                                    .font(.rtMono.bold())
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }
                            
                            Text("\(info.originName) ➔ \(info.destName)")
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.textSecondary)
                                .lineLimit(2)
                            
                            Spacer().frame(height: 6)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(info.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                                    .frame(width: 6, height: 6)
                                
                                Text(info.delayMinutes > 0 ? "\(info.delayMinutes) min delay" : "On Time")
                                    .font(.rtCaption.bold())
                                    .foregroundStyle(info.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            let originStation = StationDatabase.shared.stations.first(where: { $0.code == info.originCode })
                            let destStation = StationDatabase.shared.stations.first(where: { $0.code == info.destCode })
                            
                            selectedPrepopulatedTrip = PrepopulatedTrip(
                                origin: originStation,
                                destination: destStation,
                                trainNumber: info.trainNumber,
                                operatorName: info.operatorName
                            )
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(ColorTheme.accent)
                                Text("Add")
                                    .font(.rtCaption.bold())
                                    .foregroundStyle(ColorTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(
                    ColorTheme.surface
                        .shadow(color: Color.black.opacity(0.3), radius: 10, y: -4)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func selectAmtrakTrain(_ train: AmtrakLiveDataService.AmtrakTrain) {
        let first = train.stations.first
        let last = train.stations.last
        let originCode = first?.code ?? ""
        let destCode = last?.code ?? ""
        
        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.name ?? "Origin"
        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.name ?? "Destination"
        
        var delay = 0
        if let lastStop = train.stations.last(where: { $0.status == "Departed" || $0.status == "Station" }),
           let arrStr = lastStop.arr, let schArrStr = lastStop.schArr,
           let arrDate = AmtrakLiveDataService.shared.parseISO8601Date(arrStr),
           let schArrDate = AmtrakLiveDataService.shared.parseISO8601Date(schArrStr) {
            delay = max(0, Int(arrDate.timeIntervalSince(schArrDate) / 60))
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTrain = SelectedTrainInfo(
                trainNumber: train.trainNum,
                operatorName: "Amtrak",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.velocity.map(Int.init),
                delayMinutes: delay,
                lat: train.lat ?? 0,
                lon: train.lon ?? 0
            )
            
            if let lat = train.lat, let lon = train.lon {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 100_000,
                    longitudinalMeters: 100_000
                ))
            }
        }
    }
    
    private func selectViaTrain(number: String, train: VIALiveDataService.VIALiveTrain) {
        let first = train.times.first
        let last = train.times.last
        let originCode = first?.code ?? ""
        let destCode = last?.code ?? ""
        
        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.station ?? "Origin"
        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.station ?? "Destination"
        
        var delay = 0
        if let lastStopWithDiff = train.times.last(where: { $0.diffMin != nil }) {
            delay = max(0, lastStopWithDiff.diffMin ?? 0)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTrain = SelectedTrainInfo(
                trainNumber: number,
                operatorName: "VIA",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.speed,
                delayMinutes: delay,
                lat: train.lat ?? 0,
                lon: train.lng ?? 0
            )
            
            if let lat = train.lat, let lon = train.lng {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 100_000,
                    longitudinalMeters: 100_000
                ))
            }
        }
    }
    
    private func selectGoTrain(number: String, train: GOLiveDataService.GOLiveTrain) {
        let first = train.times.first
        let last = train.times.last
        let originCode = first?.code ?? ""
        let destCode = last?.code ?? ""
        
        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.station ?? "Origin"
        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.station ?? "Destination"
        
        var delay = 0
        if let lastStopWithDiff = train.times.last(where: { $0.diffMin != nil }) {
            delay = max(0, lastStopWithDiff.diffMin ?? 0)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTrain = SelectedTrainInfo(
                trainNumber: number,
                operatorName: "GO",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.speed,
                delayMinutes: delay,
                lat: train.lat ?? 0,
                lon: train.lng ?? 0
            )
            
            if let lat = train.lat, let lon = train.lng {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 100_000,
                    longitudinalMeters: 100_000
                ))
            }
        }
    }
}

// MARK: - Station Board View

struct StationBoardView: View {
    let amtrakTrains: [AmtrakLiveDataService.AmtrakTrain]
    let viaTrains: [String: VIALiveDataService.VIALiveTrain]
    let goTrains: [String: GOLiveDataService.GOLiveTrain]
    
    @Binding var selectedPrepopulatedTrip: PrepopulatedTrip?
    
    @State private var searchText = ""
    @State private var selectedStation: Station? = nil
    @State private var showDepartures = true
    
    var body: some View {
        VStack(spacing: 0) {
            if selectedStation == nil {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(ColorTheme.textTertiary)
                        TextField("Search station name or code…", text: $searchText, prompt: Text("Search station name or code…").foregroundColor(ColorTheme.textTertiary.opacity(0.6)))
                            .font(.rtBody.bold())
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    let filteredStations = StationDatabase.shared.stations.filter {
                        searchText.isEmpty ||
                        $0.name.localizedCaseInsensitiveContains(searchText) ||
                        $0.code.localizedCaseInsensitiveContains(searchText) ||
                        $0.city.localizedCaseInsensitiveContains(searchText)
                    }
                    
                    List(filteredStations) { station in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedStation = station
                            }
                        } label: {
                            HStack {
                                Text(station.code)
                                    .font(.rtMono.bold())
                                    .foregroundStyle(ColorTheme.operatorColor(for: station.railOperator ?? ""))
                                    .frame(width: 50, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(station.name)
                                        .font(.rtBody.bold())
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    Text("\(station.city), \(station.country)")
                                        .font(.rtCaption)
                                        .foregroundStyle(ColorTheme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(ColorTheme.textTertiary.opacity(0.1))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            } else if let station = selectedStation {
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedStation = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Back")
                                    .font(.rtBody.bold())
                            }
                            .foregroundStyle(ColorTheme.accent)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(station.name)
                            .font(.rtHeadline)
                            .foregroundStyle(ColorTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(station.code)
                            .font(.rtMono.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ColorTheme.operatorColor(for: station.railOperator ?? ""), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDepartures = true
                            }
                        } label: {
                            Text("DEPARTURES")
                                .font(.rtSubhead.bold())
                                .foregroundStyle(showDepartures ? ColorTheme.accent : ColorTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(showDepartures ? ColorTheme.accent.opacity(0.12) : Color.clear, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDepartures = false
                            }
                        } label: {
                            Text("ARRIVALS")
                                .font(.rtSubhead.bold())
                                .foregroundStyle(!showDepartures ? ColorTheme.accent : ColorTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(!showDepartures ? ColorTheme.accent.opacity(0.12) : Color.clear, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(ColorTheme.surface, in: Capsule())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    let items = getBoardItems(for: station)
                    
                    if items.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundStyle(ColorTheme.textTertiary)
                            Text(showDepartures ? "No departures today" : "No arrivals today")
                                .font(.rtHeadline)
                                .foregroundStyle(ColorTheme.textSecondary)
                            Text("Check back later or try another station.")
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(items) { item in
                                    Button {
                                        let originStation = showDepartures ? station : nil
                                        let destStation = !showDepartures ? station : nil
                                        selectedPrepopulatedTrip = PrepopulatedTrip(
                                            origin: originStation,
                                            destination: destStation,
                                            trainNumber: item.trainNumber,
                                            operatorName: item.operatorName
                                        )
                                    } label: {
                                        LEDBoardRow(item: item, isDeparture: showDepartures)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
    }
    
    struct BoardItem: Identifiable {
        let id = UUID()
        let trainNumber: String
        let operatorName: String
        let time: Date
        let secondaryStation: String
        let delayMinutes: Int
        let platform: String?
    }
    
    private func getBoardItems(for station: Station) -> [BoardItem] {
        var items: [BoardItem] = []
        
        // 1. Amtrak
        for train in amtrakTrains {
            if let stopIndex = train.stations.firstIndex(where: { $0.code == station.code }),
               let stop = train.stations[safe: stopIndex] {
                if showDepartures {
                    if stopIndex < train.stations.count - 1, let timeStr = stop.schDep ?? stop.schArr,
                       let timeDate = AmtrakLiveDataService.shared.parseISO8601Date(timeStr) {
                        let destCode = train.stations.last?.code ?? ""
                        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? train.stations.last?.name ?? "Dest"
                        
                        var delay = 0
                        if let estDepStr = stop.dep ?? stop.arr,
                           let estDate = AmtrakLiveDataService.shared.parseISO8601Date(estDepStr) {
                            delay = max(0, Int(estDate.timeIntervalSince(timeDate) / 60))
                        }
                        
                        items.append(BoardItem(
                            trainNumber: train.trainNum,
                            operatorName: "Amtrak",
                            time: timeDate,
                            secondaryStation: destName,
                            delayMinutes: delay,
                            platform: stop.platform
                        ))
                    }
                } else {
                    if stopIndex > 0, let timeStr = stop.schArr ?? stop.schDep,
                       let timeDate = AmtrakLiveDataService.shared.parseISO8601Date(timeStr) {
                        let originCode = train.stations.first?.code ?? ""
                        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? train.stations.first?.name ?? "Origin"
                        
                        var delay = 0
                        if let estArrStr = stop.arr ?? stop.dep,
                           let estDate = AmtrakLiveDataService.shared.parseISO8601Date(estArrStr) {
                            delay = max(0, Int(estDate.timeIntervalSince(timeDate) / 60))
                        }
                        
                        items.append(BoardItem(
                            trainNumber: train.trainNum,
                            operatorName: "Amtrak",
                            time: timeDate,
                            secondaryStation: originName,
                            delayMinutes: delay,
                            platform: stop.platform
                        ))
                    }
                }
            }
        }
        
        // 2. VIA Rail
        for (key, train) in viaTrains {
            let trainNum = key.split(separator: " ").first.map(String.init) ?? key
            if let stopIndex = train.times.firstIndex(where: { $0.code == station.code }),
               let stop = train.times[safe: stopIndex] {
                if showDepartures {
                    if stopIndex < train.times.count - 1, let timeStr = stop.departure?.scheduled ?? stop.scheduled,
                       let timeDate = VIALiveDataService.shared.parseISO8601Date(timeStr) {
                        let destCode = train.times.last?.code ?? ""
                        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? train.times.last?.station ?? "Dest"
                        
                        items.append(BoardItem(
                            trainNumber: trainNum,
                            operatorName: "VIA",
                            time: timeDate,
                            secondaryStation: destName,
                            delayMinutes: max(0, stop.diffMin ?? 0),
                            platform: nil
                        ))
                    }
                } else {
                    if stopIndex > 0, let timeStr = stop.arrival?.scheduled ?? stop.scheduled,
                       let timeDate = VIALiveDataService.shared.parseISO8601Date(timeStr) {
                        let originCode = train.times.first?.code ?? ""
                        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? train.times.first?.station ?? "Origin"
                        
                        items.append(BoardItem(
                            trainNumber: trainNum,
                            operatorName: "VIA",
                            time: timeDate,
                            secondaryStation: originName,
                            delayMinutes: max(0, stop.diffMin ?? 0),
                            platform: nil
                        ))
                    }
                }
            }
        }
        
        // 3. GO Transit
        for (key, train) in goTrains {
            let trainNum = key.split(separator: " ").first.map(String.init) ?? key
            if let stopIndex = train.times.firstIndex(where: { $0.code == station.code }),
               let stop = train.times[safe: stopIndex] {
                if showDepartures {
                    if stopIndex < train.times.count - 1, let timeStr = stop.departure?.scheduled ?? stop.scheduled,
                       let timeDate = GOLiveDataService.shared.parseISO8601Date(timeStr) {
                        let destCode = train.times.last?.code ?? ""
                        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? train.times.last?.station ?? "Dest"
                        
                        items.append(BoardItem(
                            trainNumber: trainNum,
                            operatorName: "GO",
                            time: timeDate,
                            secondaryStation: destName,
                            delayMinutes: max(0, stop.diffMin ?? 0),
                            platform: nil
                        ))
                    }
                } else {
                    if stopIndex > 0, let timeStr = stop.arrival?.scheduled ?? stop.scheduled,
                       let timeDate = GOLiveDataService.shared.parseISO8601Date(timeStr) {
                        let originCode = train.times.first?.code ?? ""
                        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? train.times.first?.station ?? "Origin"
                        
                        items.append(BoardItem(
                            trainNumber: trainNum,
                            operatorName: "GO",
                            time: timeDate,
                            secondaryStation: originName,
                            delayMinutes: max(0, stop.diffMin ?? 0),
                            platform: nil
                        ))
                    }
                }
            }
        }
        
        return items.sorted(by: { $0.time < $1.time })
    }
}

struct LEDBoardRow: View {
    let item: StationBoardView.BoardItem
    let isDeparture: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Text(item.time.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 1.0, green: 0.6, blue: 0.0))
                .frame(width: 75, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Train \(item.trainNumber)")
                    .font(.rtSubhead.bold())
                    .foregroundStyle(.white)
                Text(item.operatorName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(width: 80, alignment: .leading)
            
            Text(item.secondaryStation.uppercased())
                .font(.rtBody.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if item.delayMinutes > 0 {
                    Text("LATE \(item.delayMinutes)M")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.accentRed)
                } else {
                    Text("ON TIME")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.accentGreen)
                }
                
                if let plat = item.platform, !plat.isEmpty {
                    Text("PLAT \(plat)")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Active Trains List View

struct ActiveTrainsListView: View {
    let amtrakTrains: [AmtrakLiveDataService.AmtrakTrain]
    let viaTrains: [String: VIALiveDataService.VIALiveTrain]
    let goTrains: [String: GOLiveDataService.GOLiveTrain]
    
    @Binding var selectedPrepopulatedTrip: PrepopulatedTrip?
    @State private var searchText = ""
    
    struct ActiveTrainItem: Identifiable {
        let id = UUID()
        let trainNumber: String
        let operatorName: String
        let originCode: String
        let originName: String
        let destCode: String
        let destName: String
        let speed: Int?
        let delayMinutes: Int
        let platform: String?
        let originalTrainData: Any
    }
    
    private var allItems: [ActiveTrainItem] {
        var items: [ActiveTrainItem] = []
        
        // 1. Amtrak
        for train in amtrakTrains {
            let first = train.stations.first
            let last = train.stations.last
            let originCode = first?.code ?? ""
            let destCode = last?.code ?? ""
            
            let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.name ?? "Origin"
            let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.name ?? "Destination"
            
            var delay = 0
            if let lastStop = train.stations.last(where: { $0.status == "Departed" || $0.status == "Station" }),
               let arrStr = lastStop.arr, let schArrStr = lastStop.schArr,
               let arrDate = AmtrakLiveDataService.shared.parseISO8601Date(arrStr),
               let schArrDate = AmtrakLiveDataService.shared.parseISO8601Date(schArrStr) {
                delay = max(0, Int(arrDate.timeIntervalSince(schArrDate) / 60))
            }
            
            items.append(ActiveTrainItem(
                trainNumber: train.trainNum,
                operatorName: "Amtrak",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.velocity.map(Int.init),
                delayMinutes: delay,
                platform: train.stations.last(where: { $0.platform != nil })?.platform,
                originalTrainData: train
            ))
        }
        
        // 2. VIA Rail
        for (key, train) in viaTrains {
            let trainNum = key.split(separator: " ").first.map(String.init) ?? key
            let first = train.times.first
            let last = train.times.last
            let originCode = first?.code ?? ""
            let destCode = last?.code ?? ""
            
            let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.station ?? "Origin"
            let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.station ?? "Destination"
            
            var delay = 0
            if let lastStopWithDiff = train.times.last(where: { $0.diffMin != nil }) {
                delay = max(0, lastStopWithDiff.diffMin ?? 0)
            }
            
            items.append(ActiveTrainItem(
                trainNumber: trainNum,
                operatorName: "VIA",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.speed,
                delayMinutes: delay,
                platform: nil,
                originalTrainData: train
            ))
        }
        
        // 3. GO Transit
        for (key, train) in goTrains {
            let trainNum = key.split(separator: " ").first.map(String.init) ?? key
            let first = train.times.first
            let last = train.times.last
            let originCode = first?.code ?? ""
            let destCode = last?.code ?? ""
            
            let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? first?.station ?? "Origin"
            let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? last?.station ?? "Destination"
            
            var delay = 0
            if let lastStopWithDiff = train.times.last(where: { $0.diffMin != nil }) {
                delay = max(0, lastStopWithDiff.diffMin ?? 0)
            }
            
            items.append(ActiveTrainItem(
                trainNumber: trainNum,
                operatorName: "GO",
                originCode: originCode,
                originName: originName,
                destCode: destCode,
                destName: destName,
                speed: train.speed,
                delayMinutes: delay,
                platform: nil,
                originalTrainData: train
            ))
        }
        
        return items.sorted(by: { $0.trainNumber < $1.trainNumber })
    }
    
    private var filteredItems: [ActiveTrainItem] {
        allItems.filter {
            searchText.isEmpty ||
            $0.trainNumber.localizedCaseInsensitiveContains(searchText) ||
            $0.operatorName.localizedCaseInsensitiveContains(searchText) ||
            $0.originName.localizedCaseInsensitiveContains(searchText) ||
            $0.destName.localizedCaseInsensitiveContains(searchText) ||
            $0.originCode.localizedCaseInsensitiveContains(searchText) ||
            $0.destCode.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ColorTheme.textTertiary)
                TextField("Search train, route or operator…", text: $searchText, prompt: Text("Search train, route or operator…").foregroundColor(ColorTheme.textTertiary.opacity(0.6)))
                    .font(.rtBody.bold())
                    .foregroundStyle(ColorTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tram.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(ColorTheme.textTertiary)
                    Text("No active trains found")
                        .font(.rtHeadline)
                        .foregroundStyle(ColorTheme.textSecondary)
                    Text("Check spelling or refresh the feeds.")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            Button {
                                let originStation = StationDatabase.shared.stations.first(where: { $0.code == item.originCode })
                                let destStation = StationDatabase.shared.stations.first(where: { $0.code == item.destCode })
                                
                                selectedPrepopulatedTrip = PrepopulatedTrip(
                                    origin: originStation,
                                    destination: destStation,
                                    trainNumber: item.trainNumber,
                                    operatorName: item.operatorName
                                )
                            } label: {
                                ActiveTrainRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct ActiveTrainRow: View {
    let item: ActiveTrainsListView.ActiveTrainItem
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text(item.operatorName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ColorTheme.operatorColor(for: item.operatorName), in: RoundedRectangle(cornerRadius: 4))
                    
                    Text("Train \(item.trainNumber)")
                        .font(.rtBody.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                if let speed = item.speed, speed > 0 {
                    Text("\(speed) \(item.operatorName == "Amtrak" ? "mph" : "km/h")")
                        .font(.rtMono)
                        .foregroundStyle(ColorTheme.accentGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ColorTheme.accentGreen.opacity(0.1), in: Capsule())
                }
            }
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.originCode)
                        .font(.rtMono.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text(item.originName)
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textSecondary)
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.destCode)
                        .font(.rtMono.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text(item.destName)
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
            .padding(.horizontal, 4)
            
            Divider().opacity(0.08)
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                        .frame(width: 6, height: 6)
                    Text(item.delayMinutes > 0 ? "\(item.delayMinutes)m delay" : "On Time")
                        .font(.rtCaption.bold())
                        .foregroundStyle(item.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                }
                
                Spacer()
                
                if let plat = item.platform, !plat.isEmpty {
                    Text("Platform \(plat)")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textSecondary)
                }
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(ColorTheme.accent)
            }
        }
        .padding(14)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.operatorColor(for: item.operatorName).opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Collection Extensions

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
