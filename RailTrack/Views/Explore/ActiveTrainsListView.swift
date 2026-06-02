import SwiftUI

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
