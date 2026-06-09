import SwiftUI

struct TripCardView: View {
    let trip: Trip

    private var operatorColor: Color { ColorTheme.operatorColor(for: trip.trainOperator) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Op + Status
            HStack {
                HStack(spacing: 6) {
                    Text(trip.trainOperator)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(operatorColor, in: RoundedRectangle(cornerRadius: 4))

                    Text(trip.trainNumber)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                    
                    if let service = trip.serviceName {
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(ColorTheme.textTertiary.opacity(0.5))
                        Text(service.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(ColorTheme.textTertiary)
                            .tracking(0.5)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: trip.status)
            }

            // Route & Times
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.origin.code)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text(trip.scheduledDeparture.timeString)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ColorTheme.textSecondary)
                }

                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ColorTheme.textTertiary.opacity(0.3))
                    Rectangle()
                        .fill(ColorTheme.textTertiary.opacity(0.15))
                        .frame(width: 40, height: 1.5)
                    
                    Text(trip.scheduledDeparture.relativeDayString.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(ColorTheme.textTertiary)
                }
                .padding(.horizontal, 12)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(trip.destination.code)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text(trip.scheduledArrival.timeString)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    trip.status.isNegative
                        ? ColorTheme.accentAmber.opacity(0.3)
                        : ColorTheme.textTertiary.opacity(0.1),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
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
