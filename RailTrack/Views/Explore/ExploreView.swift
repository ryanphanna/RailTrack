import SwiftUI
import CoreLocation
import MapKit
import Combine

struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var locationManager = LocationManager()
    
    @State private var amtrakTrains: [AmtrakLiveDataService.AmtrakTrain] = []
    @State private var viaTrains: [String: VIALiveDataService.VIALiveTrain] = [:]
    @State private var goTrains: [String: GOLiveDataService.GOLiveTrain] = [:]
    
    @State private var isLoading = false
    @State private var selectedPrepopulatedTrip: PrepopulatedTrip? = nil
    @State private var selectedTrain: SelectedTrainInfo? = nil
    
    // Nearest station state
    @State private var nearbyDepartures: [NearbyDeparture] = []
    @State private var closestStationName: String = ""
    
    // Bottom drawer state
    enum DrawerState {
        case peek
        case expanded
    }
    @State private var drawerState: DrawerState = .peek
    @State private var dragOffset: CGFloat = 0
    
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let screenHeight = geo.size.height
                let peekHeight: CGFloat = 260
                let expandedHeight: CGFloat = screenHeight - 60
                
                let currentHeight = max(peekHeight, (drawerState == .expanded ? expandedHeight : peekHeight) - dragOffset)
                
                ZStack(alignment: .bottom) {
                    // 1. Full Screen Map in Background
                    LiveExploreMapView(
                        amtrakTrains: amtrakTrains,
                        viaTrains: viaTrains,
                        goTrains: goTrains,
                        selectedPrepopulatedTrip: $selectedPrepopulatedTrip,
                        position: $appState.sharedCameraPosition,
                        selectedTrain: $selectedTrain
                    )
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
                                    if let userLoc = locationManager.location {
                                        withAnimation(.spring()) {
                                            appState.sharedCameraPosition = .region(MKCoordinateRegion(
                                                center: userLoc.coordinate,
                                                latitudinalMeters: 50000,
                                                longitudinalMeters: 50000
                                            ))
                                        }
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
                        
                        // Header Bar
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedTrain != nil ? "Selected Train" : "Explore")
                                    .font(.rtTitle)
                                    .foregroundStyle(ColorTheme.textPrimary)
                                
                                if selectedTrain != nil {
                                    Text("Details and real-time status")
                                        .font(.rtCaption)
                                        .foregroundStyle(ColorTheme.textTertiary)
                                } else if !closestStationName.isEmpty {
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
                        .padding(.bottom, 14)
                        
                        if let info = selectedTrain {
                            SelectedTrainDrawerView(
                                info: info,
                                onClose: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedTrain = nil
                                    }
                                },
                                onAdd: {
                                    let originStation = StationDatabase.shared.stations.first(where: { $0.code == info.originCode })
                                    let destStation = StationDatabase.shared.stations.first(where: { $0.code == info.destCode })
                                    
                                    selectedPrepopulatedTrip = PrepopulatedTrip(
                                        origin: originStation,
                                        destination: destStation,
                                        trainNumber: info.trainNumber,
                                        operatorName: info.operatorName
                                    )
                                }
                            )
                        } else if drawerState == .peek {
                            VStack(spacing: 14) {
                                // Departing Soon Nearby Section
                                if !nearbyDepartures.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("DEPARTING SOON NEARBY")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(ColorTheme.textTertiary)
                                            .tracking(1.2)
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
                                } else {
                                    Text("Tap train pins on the map to see details and schedules.")
                                        .font(.rtBody)
                                        .foregroundStyle(ColorTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 10)
                                }
                                
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        drawerState = .expanded
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "tablecells.fill")
                                        Text("Search Station Boards")
                                    }
                                    .font(.rtSubhead.bold())
                                    .foregroundStyle(ColorTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(ColorTheme.surfaceHigh, in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            }
                        } else {
                            // Expanded state shows the StationBoardView directly
                            StationBoardView(
                                amtrakTrains: amtrakTrains,
                                viaTrains: viaTrains,
                                goTrains: goTrains,
                                selectedPrepopulatedTrip: $selectedPrepopulatedTrip
                            )
                            .frame(maxHeight: .infinity)
                        }
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: selectedTrain) { _, newValue in
                if newValue != nil {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        drawerState = .peek
                    }
                }
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
