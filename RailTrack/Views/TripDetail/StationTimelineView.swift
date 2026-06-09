import SwiftUI

struct StationTimelineView: View {
    let stops: [Stop]
    let operatorColor: Color

    // Origin and destination for the fallback view (shown when no stop data available)
    var origin: Station? = nil
    var destination: Station? = nil

    var body: some View {
        if stops.isEmpty, let origin, let destination {
            // Fallback: show just origin → destination when no GTFS stop data
            SimpleTwoStopView(origin: origin, destination: destination, operatorColor: operatorColor)
        } else {
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
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(stop.station.name)
                        .font(.system(size: 15, weight: isDeparted ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isDeparted ? ColorTheme.textPrimary : ColorTheme.textSecondary)

                    Spacer()

                    if let platform = stop.platform {
                        Text("PLATFORM \(platform)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(operatorColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(operatorColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    }
                }

                // Times
                HStack(spacing: 16) {
                    if let arr = stop.scheduledArrival {
                        TimeEntry(label: "ARR", scheduled: arr, actual: stop.actualArrival)
                    }
                    if let dep = stop.scheduledDeparture {
                        TimeEntry(label: "DEP", scheduled: dep, actual: stop.actualDeparture)
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 28)
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
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(ColorTheme.textTertiary)
            Text(scheduled.timeString)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textSecondary)
            if let d = delay {
                Text("+\(d)m")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.accentAmber)
            }
        }
    }
}

// MARK: - Simple Two-Stop Fallback

/// Shown when no intermediate GTFS stop data is available yet.
/// Displays a clean origin → destination dot-and-line timeline.
private struct SimpleTwoStopView: View {
    let origin: Station
    let destination: Station
    let operatorColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SimpleStopRow(name: origin.name, city: origin.city, time: nil, operatorColor: operatorColor, isOrigin: true, isLast: false)
            SimpleStopRow(name: destination.name, city: destination.city, time: nil, operatorColor: operatorColor, isOrigin: false, isLast: true)
        }
    }
}

private struct SimpleStopRow: View {
    let name: String
    let city: String
    let time: Date?
    let operatorColor: Color
    let isOrigin: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline column
            VStack(spacing: 0) {
                Circle()
                    .fill(isOrigin ? operatorColor : ColorTheme.surface)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(operatorColor, lineWidth: isOrigin ? 0 : 2))

                if !isLast {
                    Rectangle()
                        .fill(operatorColor.opacity(0.35))
                        .frame(width: 2)
                        .frame(minHeight: 44)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.rtBody)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(city)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
            }
            .padding(.bottom, isLast ? 0 : 20)

            Spacer()
        }
    }
}

#Preview {
    VStack {
        StationTimelineView(
            stops: [],
            operatorColor: ColorTheme.via,
            origin: Station(
                id: "VIA-TRTO", name: "Toronto Union Station", shortName: "Toronto",
                code: "TOR", coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806),
                timezone: "America/Toronto", railOperator: nil, city: "Toronto", country: "CA"
            ),
            destination: Station(
                id: "VIA-OTTW", name: "Ottawa Station", shortName: "Ottawa",
                code: "OTT", coordinate: Coordinate(latitude: 45.4168, longitude: -75.6561),
                timezone: "America/Toronto", railOperator: nil, city: "Ottawa", country: "CA"
            )
        )
    }
    .padding()
    .background(ColorTheme.background)
}
