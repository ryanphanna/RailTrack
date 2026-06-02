import SwiftUI

struct StationSearchResultsCard: View {
    @Binding var selectedOrigin: Station?
    @Binding var originQuery: String
    @Binding var originResults: [Station]
    @Binding var isOriginFocused: Bool
    @Binding var selectedDestination: Station?
    @Binding var destinationQuery: String
    @Binding var destinationResults: [Station]
    @Binding var isDestinationFocused: Bool
    @Binding var selectedOperator: String
    
    var body: some View {
        if isOriginFocused && !originResults.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("MATCHING ORIGIN STATIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                
                ForEach(originResults.prefix(4)) { station in
                    Button {
                        selectedOrigin = station
                        originQuery = station.name
                        originResults = []
                        isOriginFocused = false
                        if let op = station.railOperator {
                            selectedOperator = op
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(station.code)
                                .font(.rtMono)
                                .foregroundStyle(ColorTheme.operatorColor(for: station.railOperator ?? ""))
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                                Text(station.city)
                                    .font(.rtCaption)
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    
                    if station.id != originResults.prefix(4).last?.id {
                        Divider().padding(.leading, 64).opacity(0.08)
                    }
                }
            }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.operatorColor(for: selectedOperator).opacity(0.15), lineWidth: 1)
            )
        } else if isDestinationFocused && !destinationResults.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("MATCHING DESTINATION STATIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                
                ForEach(destinationResults.prefix(4)) { station in
                    Button {
                        selectedDestination = station
                        destinationQuery = station.name
                        destinationResults = []
                        isDestinationFocused = false
                        if let op = station.railOperator {
                            selectedOperator = op
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(station.code)
                                .font(.rtMono)
                                .foregroundStyle(ColorTheme.operatorColor(for: station.railOperator ?? ""))
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                                Text(station.city)
                                    .font(.rtCaption)
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    
                    if station.id != destinationResults.prefix(4).last?.id {
                        Divider().padding(.leading, 64).opacity(0.08)
                    }
                }
            }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.operatorColor(for: selectedOperator).opacity(0.15), lineWidth: 1)
            )
        }
    }
}
