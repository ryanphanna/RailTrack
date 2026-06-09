import SwiftUI
import CoreLocation

struct StationBoardView: View {
    let amtrakTrains: [AmtrakLiveDataService.AmtrakTrain]
    let viaTrains: [String: VIALiveDataService.VIALiveTrain]
    let goTrains: [String: GOLiveDataService.GOLiveTrain]
    let userLocation: CLLocation?

    @Binding var selectedStation: Station?
    @Binding var selectedPrepopulatedTrip: PrepopulatedTrip?

    @State private var searchText = ""
    @State private var showDepartures = true

    private func distanceLabel(_ station: Station) -> String? {
        guard let loc = userLocation else { return nil }
        let stLoc = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
        let km = stLoc.distance(from: loc) / 1000
        return km < 1 ? "<1 km" : "\(Int(km)) km"
    }

    private var sortedStations: [Station] {
        guard let loc = userLocation else { return StationDatabase.shared.stations }
        return StationDatabase.shared.stations.sorted {
            let a = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let b = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return a.distance(from: loc) < b.distance(from: loc)
        }
    }

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

                    let filteredStations = sortedStations.filter {
                        searchText.isEmpty ||
                        $0.name.localizedCaseInsensitiveContains(searchText) ||
                        $0.code.localizedCaseInsensitiveContains(searchText) ||
                        $0.city.localizedCaseInsensitiveContains(searchText)
                    }

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredStations) { station in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedStation = station
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(station.code)
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(ColorTheme.operatorColor(for: station.railOperator ?? "").opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
                                            .frame(width: 62, alignment: .center)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(station.name)
                                                .font(.rtBody.bold())
                                                .foregroundStyle(ColorTheme.textPrimary)
                                            Text(station.city)
                                                .font(.rtCaption)
                                                .foregroundStyle(ColorTheme.textTertiary)
                                        }

                                        Spacer()

                                        if let dist = distanceLabel(station) {
                                            Text(dist)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(ColorTheme.textTertiary)
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(ColorTheme.textTertiary.opacity(0.5))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 13)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if station.id != filteredStations.last?.id {
                                    Divider()
                                        .opacity(0.06)
                                        .padding(.leading, 20 + 62 + 12)
                                }
                            }
                        }
                    }
                }
            } else if let station = selectedStation {
                VStack(spacing: 0) {
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
                        VStack(spacing: 10) {
                            Image(systemName: "tram")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(ColorTheme.textTertiary.opacity(0.4))
                                .padding(.bottom, 4)

                            Text("No \(showDepartures ? "departures" : "arrivals") in the next 12 hours")
                                .font(.rtSubhead.bold())
                                .foregroundStyle(ColorTheme.textSecondary)
                                .multilineTextAlignment(.center)

                            Text("Service at this station may have ended for the night.")
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 48)
                        .frame(maxWidth: .infinity)
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
        let now = Date()
        let cutoffPast = now.addingTimeInterval(-30 * 60)
        let cutoffFuture = now.addingTimeInterval(12 * 60 * 60)

        func inWindow(_ date: Date) -> Bool {
            date >= cutoffPast && date <= cutoffFuture
        }

        // 1. Amtrak
        for train in amtrakTrains {
            if let stopIndex = train.stations.firstIndex(where: { $0.code == station.code }),
               let stop = train.stations[safe: stopIndex] {
                if showDepartures {
                    if stopIndex < train.stations.count - 1,
                       let timeStr = stop.schDep ?? stop.schArr,
                       let timeDate = AmtrakLiveDataService.shared.parseISO8601Date(timeStr),
                       inWindow(timeDate) {
                        let destCode = train.stations.last?.code ?? ""
                        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? train.stations.last?.name ?? "Dest"
                        var delay = 0
                        if let estDepStr = stop.dep ?? stop.arr,
                           let estDate = AmtrakLiveDataService.shared.parseISO8601Date(estDepStr) {
                            delay = max(0, Int(estDate.timeIntervalSince(timeDate) / 60))
                        }
                        items.append(BoardItem(trainNumber: train.trainNum, operatorName: "Amtrak", time: timeDate, secondaryStation: destName, delayMinutes: delay, platform: stop.platform))
                    }
                } else {
                    if stopIndex > 0,
                       let timeStr = stop.schArr ?? stop.schDep,
                       let timeDate = AmtrakLiveDataService.shared.parseISO8601Date(timeStr),
                       inWindow(timeDate) {
                        let originCode = train.stations.first?.code ?? ""
                        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? train.stations.first?.name ?? "Origin"
                        var delay = 0
                        if let estArrStr = stop.arr ?? stop.dep,
                           let estDate = AmtrakLiveDataService.shared.parseISO8601Date(estArrStr) {
                            delay = max(0, Int(estDate.timeIntervalSince(timeDate) / 60))
                        }
                        items.append(BoardItem(trainNumber: train.trainNum, operatorName: "Amtrak", time: timeDate, secondaryStation: originName, delayMinutes: delay, platform: stop.platform))
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
                    if stopIndex < train.times.count - 1,
                       let timeStr = stop.departure?.scheduled ?? stop.scheduled,
                       let timeDate = VIALiveDataService.shared.parseISO8601Date(timeStr),
                       inWindow(timeDate) {
                        let destCode = train.times.last?.code ?? ""
                        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? train.times.last?.station ?? "Dest"
                        items.append(BoardItem(trainNumber: trainNum, operatorName: "VIA", time: timeDate, secondaryStation: destName, delayMinutes: max(0, stop.diffMin ?? 0), platform: nil))
                    }
                } else {
                    if stopIndex > 0,
                       let timeStr = stop.arrival?.scheduled ?? stop.scheduled,
                       let timeDate = VIALiveDataService.shared.parseISO8601Date(timeStr),
                       inWindow(timeDate) {
                        let originCode = train.times.first?.code ?? ""
                        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? train.times.first?.station ?? "Origin"
                        items.append(BoardItem(trainNumber: trainNum, operatorName: "VIA", time: timeDate, secondaryStation: originName, delayMinutes: max(0, stop.diffMin ?? 0), platform: nil))
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
                    if stopIndex < train.times.count - 1,
                       let timeStr = stop.departure?.scheduled ?? stop.scheduled,
                       let timeDate = GOLiveDataService.shared.parseISO8601Date(timeStr),
                       inWindow(timeDate) {
                        let destCode = train.times.last?.code ?? ""
                        let destName = StationDatabase.shared.stations.first(where: { $0.code == destCode })?.shortName ?? train.times.last?.station ?? "Dest"
                        items.append(BoardItem(trainNumber: trainNum, operatorName: "GO", time: timeDate, secondaryStation: destName, delayMinutes: max(0, stop.diffMin ?? 0), platform: nil))
                    }
                } else {
                    if stopIndex > 0,
                       let timeStr = stop.arrival?.scheduled ?? stop.scheduled,
                       let timeDate = GOLiveDataService.shared.parseISO8601Date(timeStr),
                       inWindow(timeDate) {
                        let originCode = train.times.first?.code ?? ""
                        let originName = StationDatabase.shared.stations.first(where: { $0.code == originCode })?.shortName ?? train.times.first?.station ?? "Origin"
                        items.append(BoardItem(trainNumber: trainNum, operatorName: "GO", time: timeDate, secondaryStation: originName, delayMinutes: max(0, stop.diffMin ?? 0), platform: nil))
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
