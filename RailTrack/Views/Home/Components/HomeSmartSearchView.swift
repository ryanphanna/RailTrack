import SwiftUI

struct HomeSmartSearchView: View {
    let searchQuery: String
    @Binding var isSearchFocused: Bool
    @Binding var activePrepopulatedTrip: PrepopulatedTrip?
    
    let parseTrainQuery: (String) -> (number: String, op: String)?
    let parseRouteQuery: (String) -> HomeView.ParsedRoute?
    
    var body: some View {
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
                HStack(spacing: 12) {
                    Image(systemName: "plus.square.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(ColorTheme.accent)
                    Text("Manually Add Custom Trip")
                        .font(.rtBody.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                    Spacer()
                }
                .padding(16)
                .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ColorTheme.textTertiary.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}
