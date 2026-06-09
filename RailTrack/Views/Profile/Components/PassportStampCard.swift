import SwiftUI

struct PassportStampCard: View {
    let stamps: [StationStamp]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PASSPORT STAMPS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1.2)
                Spacer()
                Text("\(stamps.count) Visited")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
            }

            if stamps.isEmpty {
                Text("No stamps yet. Complete your first journey!")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(stamps) { stamp in
                            StationStampView(stamp: stamp)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(ColorTheme.textTertiary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct StationStampView: View {
    let stamp: StationStamp

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Outer circle (dashed)
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(ColorTheme.textTertiary.opacity(0.3))
                    .frame(width: 84, height: 84)

                // Inner stamp circle
                Circle()
                    .stroke(lineWidth: 2.5)
                    .foregroundStyle(ColorTheme.operatorColor(for: stamp.station.railOperator ?? "VIA").opacity(0.6))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(lineWidth: 0.5)
                            .foregroundStyle(ColorTheme.operatorColor(for: stamp.station.railOperator ?? "VIA").opacity(0.3))
                            .padding(4)
                    )

                VStack(spacing: 0) {
                    Text(stamp.station.code)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    Rectangle()
                        .fill(ColorTheme.textTertiary.opacity(0.3))
                        .frame(width: 40, height: 1)
                        .padding(.vertical, 2)

                    Text(stamp.date.formatted(.dateTime.year()))
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
            .rotationEffect(.degrees(-10)) // Slight tilt for authenticity

            VStack(spacing: 2) {
                Text(stamp.station.shortName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(stamp.station.city)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(ColorTheme.textTertiary)
            }
            .lineLimit(1)
        }
        .frame(width: 90)
    }
}
