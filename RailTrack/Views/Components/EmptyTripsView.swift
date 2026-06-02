import SwiftUI

struct EmptyTripsView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "tram")
                    .font(.system(size: 32))
                    .foregroundStyle(ColorTheme.accent)
            }
            
            VStack(spacing: 8) {
                Text("No upcoming trips")
                    .font(.rtHeadline)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Search for a train number or route above to add your first journey.")
                    .font(.rtBody)
                    .foregroundStyle(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}
