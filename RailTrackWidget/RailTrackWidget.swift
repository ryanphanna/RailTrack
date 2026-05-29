import SwiftUI
import WidgetKit
import ActivityKit

struct TripLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            // Lock Screen Banner UI
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(hex: "#121214").opacity(0.85))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "tram.fill")
                            .foregroundStyle(ColorTheme.operatorColor(for: context.attributes.trainOperator))
                        Text("\(context.attributes.trainOperator) \(context.attributes.trainNumber)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.statusLabel)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(context.state.isNegativeStatus ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (context.state.isNegativeStatus ? ColorTheme.accentAmber : ColorTheme.accentGreen).opacity(0.12),
                            in: Capsule()
                        )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Route segment
                        HStack {
                            Text(context.attributes.originCode)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textSecondary)
                            
                            Spacer()
                            
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 4)
                                    
                                    Capsule()
                                        .fill(ColorTheme.operatorColor(for: context.attributes.trainOperator))
                                        .frame(width: geo.size.width * CGFloat(context.state.progressFraction), height: 4)
                                    
                                    Image(systemName: "tram.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(ColorTheme.operatorColor(for: context.attributes.trainOperator))
                                        .offset(x: (geo.size.width - 10) * CGFloat(context.state.progressFraction) - 5, y: -3)
                                }
                            }
                            .frame(height: 12)
                            .padding(.horizontal, 8)
                            
                            Spacer()
                            
                            Text(context.attributes.destinationCode)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textSecondary)
                        }
                        
                        HStack {
                            Label("Next: \(context.state.nextStationName)", systemImage: "arrow.right.circle.fill")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(ColorTheme.textTertiary)
                            
                            Spacer()
                            
                            Text("ETA: \(context.state.estimatedArrivalTime.timeString)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textPrimary)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ColorTheme.operatorColor(for: context.attributes.trainOperator))
                    Text(context.attributes.trainNumber)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            } compactTrailing: {
                Text(context.state.delayMinutes > 0 ? "+\(context.state.delayMinutes)m" : "ETA \(context.state.estimatedArrivalTime.timeString)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(context.state.isNegativeStatus ? ColorTheme.accentAmber : ColorTheme.accentGreen)
            } minimal: {
                Image(systemName: "tram.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(context.state.isNegativeStatus ? ColorTheme.accentAmber : ColorTheme.accentGreen)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TripActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Top row: branding and ETA
            HStack {
                HStack(spacing: 6) {
                    Text(context.attributes.trainOperator)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(ColorTheme.operatorColor(for: context.attributes.trainOperator), in: RoundedRectangle(cornerRadius: 4))
                    
                    Text("Train \(context.attributes.trainNumber)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
                
                Spacer()
                
                Text(context.state.statusLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(context.state.isNegativeStatus ? ColorTheme.accentAmber : ColorTheme.accentGreen)
            }
            
            // Route progress row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.originCode)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text("Departed")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(ColorTheme.textTertiary)
                }
                
                Spacer()
                
                // Route track bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(ColorTheme.operatorColor(for: context.attributes.trainOperator))
                        .frame(width: 140 * CGFloat(context.state.progressFraction), height: 6)
                    
                    Image(systemName: "tram.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(ColorTheme.operatorColor(for: context.attributes.trainOperator))
                        .offset(x: 130 * CGFloat(context.state.progressFraction) - 5, y: -4)
                }
                .frame(width: 140)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.attributes.destinationCode)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text("ETA \(context.state.estimatedArrivalTime.timeString)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
            
            // Footer details
            HStack {
                Text("Next stop: \(context.state.nextStationName)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(ColorTheme.textTertiary)
                Spacer()
            }
        }
        .padding(16)
    }
}
