import SwiftUI

struct AgenciesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header text
                    VStack(spacing: 6) {
                        Text("Transit Agencies")
                            .font(.rtTitle)
                            .foregroundStyle(ColorTheme.textPrimary)
                        
                        Text("RailTrack connects directly to transit agency APIs to provide real-time updates and schedule information.")
                            .font(.rtBody)
                            .foregroundStyle(ColorTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // VIA Rail Card
                    AgencyCard(
                        name: "VIA Rail Canada",
                        opCode: "VIA",
                        color: ColorTheme.via,
                        status: "Live Tracking Active",
                        statusColor: ColorTheme.accentGreen,
                        features: [
                            AgencyFeature(name: "Live GPS Train Tracking", supported: true),
                            AgencyFeature(name: "Real-Time Delay Metrics", supported: true),
                            AgencyFeature(name: "Corridor Timetable Auto-Lookup", supported: true),
                            AgencyFeature(name: "Dynamic Island & Lock Screen Live Activities", supported: true)
                        ]
                    )
                    
                    // Amtrak Card
                    AgencyCard(
                        name: "Amtrak (US)",
                        opCode: "Amtrak",
                        color: ColorTheme.amtrak,
                        status: "Live Tracking Active",
                        statusColor: ColorTheme.accentGreen,
                        features: [
                            AgencyFeature(name: "Live GPS Train Tracking", supported: true),
                            AgencyFeature(name: "Real-Time Delay Metrics", supported: true),
                            AgencyFeature(name: "Timetable Auto-Lookup", supported: true),
                            AgencyFeature(name: "Dynamic Island & Lock Screen Live Activities", supported: true)
                        ]
                    )
                    
                    // GO Transit Card
                    AgencyCard(
                        name: "GO Transit (Ontario)",
                        opCode: "GO",
                        color: ColorTheme.go,
                        status: "Offline Schedules",
                        statusColor: ColorTheme.textTertiary,
                        features: [
                            AgencyFeature(name: "Local Database Timetables", supported: true),
                            AgencyFeature(name: "Live Updates", supported: false, description: "GTFS-RT planned for future release")
                        ]
                    )
                    
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Agencies")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

private struct AgencyCard: View {
    let name: String
    let opCode: String
    let color: Color
    let status: String
    let statusColor: Color
    let features: [AgencyFeature]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.rtHeadline)
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    Text(opCode)
                        .font(.rtCaption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color, in: RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
                
                // Status Badge
                Text(status)
                    .font(.rtCaption.bold())
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }
            
            Divider().opacity(0.08)
            
            // Features list
            VStack(alignment: .leading, spacing: 10) {
                Text("FEATURES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                
                ForEach(features, id: \.name) { feature in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: feature.supported ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(feature.supported ? ColorTheme.accentGreen : ColorTheme.textTertiary.opacity(0.5))
                            .padding(.top, 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.name)
                                .font(.rtBody)
                                .foregroundStyle(feature.supported ? ColorTheme.textPrimary : ColorTheme.textSecondary)
                            
                            if let desc = feature.description {
                                Text(desc)
                                    .font(.rtCaption)
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AgencyFeature {
    let name: String
    let supported: Bool
    var description: String? = nil
}
