import SwiftUI

struct RouteSuggestionsCard: View {
    let isFetchingSuggestions: Bool
    @Binding var routeTrains: [RouteTrainSuggestion]
    @Binding var trainNumber: String
    @Binding var selectedOperator: String
    @Binding var departureDate: Date
    @Binding var arrivalDate: Date
    
    var body: some View {
        if isFetchingSuggestions {
            HStack(spacing: 8) {
                ProgressView().tint(ColorTheme.accent)
                Text("Finding trains on this route...")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
        } else if !routeTrains.isEmpty && trainNumber.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECOMMENDED TRAINS ON THIS ROUTE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    ForEach(routeTrains) { suggestion in
                        Button {
                            trainNumber = suggestion.trainNumber
                            selectedOperator = suggestion.operatorName
                            if let dep = suggestion.scheduledDeparture {
                                departureDate = dep
                            }
                            if let arr = suggestion.scheduledArrival {
                                arrivalDate = arr
                            }
                            routeTrains = []
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tram.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(ColorTheme.operatorColor(for: suggestion.operatorName))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(suggestion.operatorName) Train \(suggestion.trainNumber)")
                                        .font(.rtBody.bold())
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    
                                    if let dep = suggestion.scheduledDeparture {
                                        Text("Departs \(dep.formatted(.dateTime.hour().minute()))")
                                            .font(.rtCaption)
                                            .foregroundStyle(ColorTheme.textSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("Select")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(ColorTheme.operatorColor(for: suggestion.operatorName))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(ColorTheme.operatorColor(for: suggestion.operatorName).opacity(0.12), in: Capsule())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if suggestion.id != routeTrains.last?.id {
                            Divider().padding(.leading, 42).opacity(0.08)
                        }
                    }
                }
                .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ColorTheme.accent.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }
}
