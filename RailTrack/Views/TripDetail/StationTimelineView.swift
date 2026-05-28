import SwiftUI

struct StationTimelineView: View {
    let stops: [Stop]
    let operatorColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                StopRow(
                    stop: stop,
                    operatorColor: operatorColor,
                    isLast: index == stops.count - 1
                )
            }
        }
    }
}

private struct StopRow: View {
    let stop: Stop
    let operatorColor: Color
    let isLast: Bool

    private var isDeparted: Bool {
        stop.actualDeparture != nil || stop.actualArrival != nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // Timeline column
            VStack(spacing: 0) {
                Circle()
                    .fill(isDeparted ? operatorColor : ColorTheme.surface)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(operatorColor, lineWidth: isDeparted ? 0 : 2))

                if !isLast {
                    Rectangle()
                        .fill(isDeparted ? operatorColor.opacity(0.5) : ColorTheme.textTertiary.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 44)
                }
            }

            // Stop details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stop.station.name)
                        .font(.rtBody)
                        .foregroundStyle(isDeparted ? ColorTheme.textPrimary : ColorTheme.textSecondary)

                    Spacer()

                    if let platform = stop.platform {
                        Text("Pl. \(platform)")
                            .font(.rtCaption)
                            .foregroundStyle(ColorTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ColorTheme.accent.opacity(0.1), in: Capsule())
                    }
                }

                // Times
                HStack(spacing: 12) {
                    if let arr = stop.scheduledArrival {
                        TimeEntry(label: "Arr", scheduled: arr, actual: stop.actualArrival)
                    }
                    if let dep = stop.scheduledDeparture {
                        TimeEntry(label: "Dep", scheduled: dep, actual: stop.actualDeparture)
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

private struct TimeEntry: View {
    let label: String
    let scheduled: Date
    let actual: Date?

    private var delay: Int? {
        guard let actual else { return nil }
        let diff = Int(actual.timeIntervalSince(scheduled) / 60)
        return diff > 0 ? diff : nil
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.rtCaption)
                .foregroundStyle(ColorTheme.textTertiary)
            Text(scheduled.timeString)
                .font(.rtCaption.monospacedDigit())
                .foregroundStyle(ColorTheme.textSecondary)
            if let d = delay {
                Text("+\(d)m")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.accentAmber)
            }
        }
    }
}

#Preview {
    StationTimelineView(
        stops: MockDataService.shared.sampleTrips[0].stops,
        operatorColor: ColorTheme.via
    )
    .padding()
    .background(ColorTheme.background)
}
