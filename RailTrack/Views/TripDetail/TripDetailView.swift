import SwiftUI
import MapKit
import SwiftData

struct TripDetailView: View {
    let record: TripRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    // Derive display model from the persisted record
    private var trip: Trip { record.toTrip() }
    private var operatorColor: Color { ColorTheme.operatorColor(for: trip.trainOperator) }

    private var shareText: String {
        """
        I'm taking \(trip.trainOperator) \(trip.trainNumber) 🚆
        \(trip.origin.shortName) → \(trip.destination.shortName)
        Departs: \(trip.scheduledDeparture.relativeDayString) at \(trip.scheduledDeparture.timeString)
        Arrives: \(trip.scheduledArrival.relativeDayString) at \(trip.scheduledArrival.timeString)
        Tracked with RailTrack
        """
    }

    var body: some View {
        ZStack(alignment: .top) {
            ColorTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Map
                    LiveMapView(trip: trip)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                    VStack(alignment: .leading, spacing: 20) {

                        // Train header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(trip.trainOperator)
                                        .font(.rtCaption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(operatorColor, in: RoundedRectangle(cornerRadius: 6))

                                    Text("Train \(trip.trainNumber)")
                                        .font(.rtSubhead)
                                        .foregroundStyle(ColorTheme.textSecondary)
                                }

                                Text("\(trip.origin.shortName) → \(trip.destination.shortName)")
                                    .font(.rtTitle)
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }

                            Spacer()

                            StatusBadge(status: trip.status)
                        }

                        // Delay banner
                        if let delay = trip.delayMinutes {
                            DelayBanner(
                                delayMinutes: delay,
                                message: "Running late due to freight traffic."
                            )
                        }

                        // Platform chip
                        if let platform = trip.currentPlatform, !platform.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "signpost.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(operatorColor)
                                Text("Platform \(platform)")
                                    .font(.rtCaption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(operatorColor.opacity(0.12), in: Capsule())
                        }

                        // Time summary row
                        TimeSummaryRow(trip: trip)

                        Divider().opacity(0.12)

                        // Station timeline
                        Text("Route")
                            .font(.rtSubhead)
                            .foregroundStyle(ColorTheme.textSecondary)

                        StationTimelineView(stops: trip.stops, operatorColor: operatorColor)

                        Divider().opacity(0.12)

                        // Mark as Completed — shown for active or upcoming trips only
                        if trip.isActive || trip.isUpcoming {
                            if trip.status != .cancelled {
                                Button { markCompleted() } label: {
                                    Label(
                                        trip.isActive ? "Mark Arrived" : "Mark Completed",
                                        systemImage: "flag.checkered"
                                    )
                                    .font(.rtSubhead)
                                    .foregroundStyle(ColorTheme.accentGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(ColorTheme.accentGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }

                        // Notes
                        if let notes = record.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.rtCaption)
                                    .foregroundStyle(ColorTheme.textTertiary)
                                Text(notes)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textSecondary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                        }

                        // Share button
                        ShareLink(
                            item: shareText,
                            subject: Text("My Train Trip"),
                            message: Text(shareText)
                        ) {
                            Label("Share Trip", systemImage: "square.and.arrow.up")
                                .font(.rtSubhead)
                                .foregroundStyle(ColorTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ColorTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button { showEdit = true } label: {
                        Image(systemName: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditTripView(record: record)
        }
        .confirmationDialog(
            "Delete \"\(trip.trainOperator) \(trip.trainNumber)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Trip", role: .destructive) { deleteRecord() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the trip and cancel its reminders.")
        }
    }

    // MARK: - Actions

    private func markCompleted() {
        record.statusRaw = "completed"
        record.actualArrival = Date()
        record.delayMinutes = 0
        NotificationService.shared.cancelNotifications(for: record.toTrip())
    }

    private func deleteRecord() {
        NotificationService.shared.cancelNotifications(for: record.toTrip())
        modelContext.delete(record)
        dismiss()
    }
}

// MARK: - Time Summary Row

private struct TimeSummaryRow: View {
    let trip: Trip

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Departs")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                Text(trip.scheduledDeparture.timeString)
                    .font(.rtMono)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(trip.scheduledDeparture.relativeDayString)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "arrow.right")
                    .foregroundStyle(ColorTheme.textTertiary)
                Text(trip.scheduledDurationMinutes.durationString)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Arrives")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                Text(trip.scheduledArrival.timeString)
                    .font(.rtMono)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(trip.scheduledArrival.relativeDayString)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
        .padding(16)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripRecord.self, configurations: config)
    let origin = Station(
        id: "VIA-TRTO", name: "Toronto Union Station", shortName: "Toronto",
        code: "TOR", coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806),
        timezone: "America/Toronto", railOperator: nil, city: "Toronto", country: "CA"
    )
    let dest = Station(
        id: "VIA-OTTW", name: "Ottawa Station", shortName: "Ottawa",
        code: "OTT", coordinate: Coordinate(latitude: 45.4168, longitude: -75.6561),
        timezone: "America/Toronto", railOperator: nil, city: "Ottawa", country: "CA"
    )
    let record = TripRecord(
        trainNumber: "60", trainOperator: "VIA",
        origin: origin, destination: dest,
        scheduledDeparture: Calendar.current.date(byAdding: .minute, value: -90, to: Date())!,
        scheduledArrival: Calendar.current.date(byAdding: .minute, value: 150, to: Date())!,
        status: .delayed(minutes: 12),
        currentPlatform: "8"
    )
    container.mainContext.insert(record)
    return NavigationStack {
        TripDetailView(record: record)
    }
    .modelContainer(container)
}
