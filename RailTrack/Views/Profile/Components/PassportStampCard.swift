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
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .foregroundStyle(ColorTheme.operatorColor(for: stamp.station.railOperator ?? "VIA").opacity(0.4))
                    .frame(width: 72, height: 72)

                VStack(spacing: 2) {
                    Text(stamp.station.code)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text(stamp.date.formatted(.dateTime.year()))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                }
            }

            Text(stamp.station.shortName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(ColorTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}
