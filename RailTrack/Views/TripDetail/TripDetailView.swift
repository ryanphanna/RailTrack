import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: Trip
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    private var operatorColor: Color { ColorTheme.operatorColor(for: trip.trainOperator) }

    var body: some View {
        ZStack(alignment: .top) {
            ColorTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Map
                    LiveMapView(trip: trip)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                    VStack(alignment: .leading, spacing: 20) {

                        // Train header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(trip.trainOperator)
                                        .font(.rtCaption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(operatorColor, in: RoundedRectangle(cornerRadius: 6))

                                    Text("Train \(trip.trainNumber)")
                                        .font(.rtSubhead)
                                        .foregroundStyle(ColorTheme.textSecondary)
                                }

                                Text("\(trip.origin.shortName) → \(trip.destination.shortName)")
                                    .font(.rtTitle)
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }

                            Spacer()

                            StatusBadge(status: trip.status)
                        }

                        // Delay banner
                        if let delay = trip.delayMinutes {
                            DelayBanner(
                                delayMinutes: delay,
                                message: "Running late due to freight traffic."
                            )
                        }

                        // Time summary row
                        TimeSummaryRow(trip: trip)

                        Divider().opacity(0.12)

                        // Station timeline
                        Text("Route")
                            .font(.rtSubhead)
                            .foregroundStyle(ColorTheme.textSecondary)

                        StationTimelineView(stops: trip.stops, operatorColor: operatorColor)

                        Divider().opacity(0.12)

                        // Share button
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share Trip", systemImage: "square.and.arrow.up")
                                .font(.rtSubhead)
                                .foregroundStyle(ColorTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ColorTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Time Summary Row

private struct TimeSummaryRow: View {
    let trip: Trip

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Departs")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                Text(trip.scheduledDeparture.timeString)
                    .font(.rtMono)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(trip.scheduledDeparture.relativeDayString)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "arrow.right")
                    .foregroundStyle(ColorTheme.textTertiary)
                Text(trip.scheduledDurationMinutes.durationString)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Arrives")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                Text(trip.scheduledArrival.timeString)
                    .font(.rtMono)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(trip.scheduledArrival.relativeDayString)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
        .padding(16)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        TripDetailView(trip: MockDataService.shared.sampleTrips[0])
    }
}
