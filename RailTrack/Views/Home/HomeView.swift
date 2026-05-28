import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripRecord.scheduledDeparture, order: .forward) private var records: [TripRecord]
    @State private var showAddTrip = false

    // MARK: - Filtered sections
    private var trips: [Trip] { records.map { $0.toTrip() } }
    private var activeTrip: Trip? { trips.first(where: { $0.isActive }) }
    private var upcomingTrips: [Trip] { trips.filter { $0.isUpcoming } }
    private var pastTrips: [Trip] { trips.filter { !$0.isActive && !$0.isUpcoming }.reversed() }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {

                        // Active trip
                        if let active = activeTrip {
                            Section {
                                NavigationLink(destination: TripDetailView(trip: active)) {
                                    TripCardView(trip: active)
                                        .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)
                            } header: {
                                SectionHeader(title: "Now Boarding", icon: "tram.fill", color: ColorTheme.accentGreen)
                            }
                        }

                        // Upcoming
                        if !upcomingTrips.isEmpty {
                            Section {
                                ForEach(upcomingTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        TripCardView(trip: trip)
                                            .padding(.horizontal, 20)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTrip(id: trip.id)
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
                        if !pastTrips.isEmpty {
                            Section {
                                ForEach(pastTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        TripCardView(trip: trip)
                                            .padding(.horizontal, 20)
                                            .opacity(0.65)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTrip(id: trip.id)
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
