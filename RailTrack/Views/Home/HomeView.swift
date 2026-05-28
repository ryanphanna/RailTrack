import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showAddTrip = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {

                        // Active trip (if any)
                        if let active = vm.activeTrip {
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

                        // Upcoming trips
                        if !vm.upcomingTrips.isEmpty {
                            Section {
                                ForEach(vm.upcomingTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        TripCardView(trip: trip)
                                            .padding(.horizontal, 20)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                SectionHeader(title: "Upcoming", icon: "calendar", color: ColorTheme.accent)
                            }
                        }

                        // Past trips
                        if !vm.pastTrips.isEmpty {
                            Section {
                                ForEach(vm.pastTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        TripCardView(trip: trip)
                                            .padding(.horizontal, 20)
                                            .opacity(0.7)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                SectionHeader(title: "Past Trips", icon: "clock.arrow.trianglehead.counterclockwise.rotate.90", color: ColorTheme.textTertiary)
                            }
                        }

                        // Empty state
                        if vm.allTrips.isEmpty {
                            EmptyTripsView()
                                .padding(.top, 60)
                        }

                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                .refreshable { await vm.loadTrips() }

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
            .task { await vm.loadTrips() }
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

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var allTrips: [Trip] = []
    @Published var isLoading = false

    var activeTrip: Trip? { allTrips.first(where: { $0.isActive }) }
    var upcomingTrips: [Trip] { allTrips.filter { $0.isUpcoming }.sorted { $0.scheduledDeparture < $1.scheduledDeparture } }
    var pastTrips: [Trip] { allTrips.filter { !$0.isActive && !$0.isUpcoming }.sorted { $0.scheduledDeparture > $1.scheduledDeparture } }

    func loadTrips() async {
        isLoading = true
        defer { isLoading = false }
        do {
            allTrips = try await SupabaseService.shared.fetchTrips()
        } catch {
            print("Error loading trips: \(error)")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
