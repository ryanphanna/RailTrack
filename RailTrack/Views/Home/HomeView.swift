import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripRecord.scheduledDeparture, order: .forward) private var records: [TripRecord]
    @State private var showAddTrip = false

    // MARK: - Filtered sections (operate directly on TripRecord to avoid double-conversion)
    private var activeRecord: TripRecord? {
        records.first(where: { $0.toTrip().isActive })
    }
    private var upcomingRecords: [TripRecord] {
        records.filter { $0.toTrip().isUpcoming }
    }
    private var pastRecords: [TripRecord] {
        // Records are sorted ascending; reverse so most-recent past trips appear first
        Array(records.filter {
            let t = $0.toTrip(); return !t.isActive && !t.isUpcoming
        }.reversed())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {

                        // Active trip
                        if let rec = activeRecord {
                            Section {
                                NavigationLink(destination: TripDetailView(record: rec)) {
                                    TripCardView(trip: rec.toTrip())
                                        .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)
                            } header: {
                                SectionHeader(title: "Now Boarding", icon: "tram.fill", color: ColorTheme.accentGreen)
                            }
                        }

                        // Upcoming
                        if !upcomingRecords.isEmpty {
                            Section {
                                ForEach(upcomingRecords) { rec in
                                    NavigationLink(destination: TripDetailView(record: rec)) {
                                        TripCardView(trip: rec.toTrip())
                                            .padding(.horizontal, 20)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTrip(id: rec.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                SectionHeader(title: "Upcoming", icon: "calendar", color: ColorTheme.accent)
                            }
                        }

                        // Past
                        if !pastRecords.isEmpty {
                            Section {
                                ForEach(pastRecords) { rec in
                                    NavigationLink(destination: TripDetailView(record: rec)) {
                                        TripCardView(trip: rec.toTrip())
                                            .padding(.horizontal, 20)
                                            .opacity(0.65)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTrip(id: rec.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                SectionHeader(title: "Past Trips", icon: "clock.arrow.trianglehead.counterclockwise.rotate.90", color: ColorTheme.textTertiary)
                            }
                        }

                        // Empty state
                        if records.isEmpty {
                            EmptyTripsView()
                                .padding(.top, 60)
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 8)
                }

                // FAB
                Button {
                    showAddTrip = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(ColorTheme.accent, in: Circle())
                        .shadow(color: ColorTheme.accent.opacity(0.5), radius: 16, x: 0, y: 6)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("RailTrack")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddTrip) {
                AddTripView()
            }
        }
    }

    // MARK: - Delete

    private func deleteTrip(id: UUID) {
        if let record = records.first(where: { $0.id == id }) {
            NotificationService.shared.cancelNotifications(for: record.toTrip())
            modelContext.delete(record)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.rtCaption)
                .fontWeight(.bold)
                .foregroundStyle(ColorTheme.textSecondary)
                .kerning(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Empty State

private struct EmptyTripsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.system(size: 52))
                .foregroundStyle(ColorTheme.textTertiary)
            Text("No trips yet")
                .font(.rtHeadline)
                .foregroundStyle(ColorTheme.textPrimary)
            Text("Tap + to add your first train journey.")
                .font(.rtBody)
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .modelContainer(for: TripRecord.self, inMemory: true)
}
