import SwiftUI
import MapKit
import SwiftData

struct TripDetailView: View {
    let record: TripRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var isMapExpanded = false
    
    @ObservedObject private var viaLiveDataService = VIALiveDataService.shared
    @ObservedObject private var amtrakLiveDataService = AmtrakLiveDataService.shared
    @ObservedObject private var goLiveDataService = GOLiveDataService.shared

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

    private var displayedStops: [Stop] {
        let allStops: [Stop]?
        if trip.trainOperator.uppercased() == "VIA" {
            allStops = viaLiveDataService.liveStops[trip.id]
        } else if trip.trainOperator.uppercased() == "AMTRAK" {
            allStops = amtrakLiveDataService.liveStops[trip.id]
        } else if trip.trainOperator.uppercased() == "GO" {
            allStops = goLiveDataService.liveStops[trip.id]
        } else {
            allStops = nil
        }
        
        guard let stops = allStops else {
            return trip.stops
        }
        
        // Find indices of trip.origin and trip.destination in stops
        if let originIndex = stops.firstIndex(where: { $0.station.code == trip.origin.code }),
           let destIndex = stops.firstIndex(where: { $0.station.code == trip.destination.code }),
           originIndex <= destIndex {
            
            var segmentStops = Array(stops[originIndex...destIndex])
            
            // Mark the first stop as origin and the last as destination for rendering
            for i in 0..<segmentStops.count {
                segmentStops[i].isOrigin = (i == 0)
                segmentStops[i].isDestination = (i == segmentStops.count - 1)
            }
            return segmentStops
        }
        
        return stops
    }

    var body: some View {
        ZStack(alignment: .top) {
            ColorTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Map
                    LiveMapView(trip: trip, stops: displayedStops)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                isMapExpanded = true
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .padding(12)
                            }
                        }

                    VStack(alignment: .leading, spacing: 24) {

                        // Header: Operator + Route
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Text(trip.trainOperator)
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(operatorColor, in: RoundedRectangle(cornerRadius: 4))

                                Text("TRAIN \(trip.trainNumber)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ColorTheme.textTertiary)
                                    .tracking(1.0)
                                
                                if let service = trip.serviceName {
                                    Text("•")
                                        .font(.system(size: 8))
                                        .foregroundStyle(ColorTheme.textTertiary.opacity(0.5))
                                    Text(service.uppercased())
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(ColorTheme.textTertiary)
                                        .tracking(0.5)
                                }
                                
                                Spacer()
                                
                                StatusBadge(status: trip.status)
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(trip.origin.shortName)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(ColorTheme.textPrimary)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(ColorTheme.textTertiary.opacity(0.5))
                                
                                Text(trip.destination.shortName)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }
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

                        StationTimelineView(
                            stops: displayedStops,
                            operatorColor: operatorColor,
                            origin: trip.origin,
                            destination: trip.destination
                        )

                        Divider().opacity(0.12)

                        // Notes
                        if let notes = record.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NOTES")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ColorTheme.textTertiary)
                                    .tracking(0.5)
                                Text(notes)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textSecondary)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
                        }

                        // Actions Section
                        VStack(spacing: 12) {
                            ShareLink(
                                item: shareText,
                                subject: Text("My Train Trip"),
                                message: Text(shareText)
                            ) {
                                Label("Share Journey", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(ColorTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: ColorTheme.accent.opacity(0.3), radius: 8, y: 4)
                            }

                            if trip.isActive || trip.isUpcoming {
                                if trip.status != .cancelled {
                                    Button { markCompleted() } label: {
                                        Text(trip.isActive ? "Mark as Arrived" : "Mark as Completed")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(ColorTheme.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .fullScreenCover(isPresented: $isMapExpanded) {
                NavigationStack {
                    LiveMapView(trip: trip, stops: displayedStops)
                        .ignoresSafeArea(edges: .all)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    isMapExpanded = false
                                }
                                .font(.rtSubhead.bold())
                                .foregroundStyle(ColorTheme.accent)
                            }
                        }
                }
            }
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
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DEPARTS")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(0.5)
                
                Text(trip.scheduledDeparture.timeString)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                
                Text(trip.scheduledDeparture.relativeDayString.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.textSecondary)
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(ColorTheme.textTertiary.opacity(0.4))
                
                Rectangle()
                    .fill(ColorTheme.textTertiary.opacity(0.2))
                    .frame(width: 40, height: 1.5)
                
                Text(trip.scheduledDurationMinutes.durationString)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("ARRIVES")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(0.5)
                
                Text(trip.scheduledArrival.timeString)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                
                Text(trip.scheduledArrival.relativeDayString.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
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
