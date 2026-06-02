import SwiftUI

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
