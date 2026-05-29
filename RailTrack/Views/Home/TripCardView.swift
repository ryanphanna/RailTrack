import SwiftUI

struct TripCardView: View {
    let trip: Trip

    private var operatorColor: Color { ColorTheme.operatorColor(for: trip.trainOperator) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                // Header strip
                HStack {
                    // Operator badge
                    Text(trip.trainOperator)
                        .font(.rtCaption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(operatorColor, in: RoundedRectangle(cornerRadius: 6))

                    Text("Train \(trip.trainNumber)")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textSecondary)

                    Spacer()

                    StatusBadge(status: trip.status)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().opacity(0.1)

                // Route row
                HStack(alignment: .center, spacing: 0) {
                    // Origin
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.origin.code)
                            .font(.rtMono)
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text(trip.scheduledDeparture.timeString)
                            .font(.rtCaption)
                            .foregroundStyle(ColorTheme.textSecondary)
                        if let actual = trip.actualDeparture, trip.isActive {
                            Text(actual.timeString)
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.accentAmber)
                        }
                    }
                    .frame(minWidth: 50, alignment: .leading)

                    // Route line
                    RouteLineView(operatorColor: operatorColor)
                        .padding(.horizontal, 10)

                    // Destination
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(trip.destination.code)
                            .font(.rtMono)
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text(trip.scheduledArrival.timeString)
                            .font(.rtCaption)
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                    .frame(minWidth: 50, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // Footer
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(ColorTheme.textTertiary)
                    Text(trip.scheduledDeparture.relativeDayString)
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textTertiary)

                    Spacer()

                    Text(trip.scheduledDurationMinutes.durationString)
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textTertiary)

                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(ColorTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        trip.status.isNegative
                            ? ColorTheme.accentAmber.opacity(0.3)
                            : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Route Line

private struct RouteLineView: View {
    let operatorColor: Color

    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(operatorColor)
                .frame(width: 7, height: 7)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [operatorColor, operatorColor.opacity(0.4)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 2)

            Image(systemName: "tram.fill")
                .font(.system(size: 12))
                .foregroundStyle(operatorColor)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [operatorColor.opacity(0.4), operatorColor],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 2)

            Circle()
                .fill(operatorColor)
                .frame(width: 7, height: 7)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TripCardView(trip: MockDataService.shared.sampleTrips[0])
        TripCardView(trip: MockDataService.shared.sampleTrips[1])
        TripCardView(trip: MockDataService.shared.sampleTrips[2])
    }
    .padding()
    .background(ColorTheme.background)
}
