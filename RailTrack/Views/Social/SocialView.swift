import SwiftUI

struct SocialView: View {
    // Mock friends data
    private let friends: [FriendTrip] = [
        FriendTrip(id: UUID(), name: "Alex M.", initials: "AM",
                   trainOperator: "VIA", trainNumber: "60",
                   origin: "Toronto", destination: "Ottawa",
                   status: .onTime, minutesUntilArrival: 45),
        FriendTrip(id: UUID(), name: "Sarah K.", initials: "SK",
                   trainOperator: "GO", trainNumber: "152",
                   origin: "Hamilton", destination: "Toronto",
                   status: .delayed(minutes: 8), minutesUntilArrival: 22),
        FriendTrip(id: UUID(), name: "James R.", initials: "JR",
                   trainOperator: "Amtrak", trainNumber: "449",
                   origin: "Toronto", destination: "New York",
                   status: .onTime, minutesUntilArrival: nil)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if friends.isEmpty {
                        EmptySocialView()
                    } else {
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(friends) { friend in
                                    FriendTripCard(friend: friend)
                                        .padding(.horizontal, 20)
                                }
                                Color.clear.frame(height: 20)
                            }
                            .padding(.top, 12)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Add friend
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(ColorTheme.accent)
                    }
                }
            }
        }
    }
}

// MARK: - Data

struct FriendTrip: Identifiable {
    let id: UUID
    var name: String
    var initials: String
    var trainOperator: String
    var trainNumber: String
    var origin: String
    var destination: String
    var status: TripStatus
    var minutesUntilArrival: Int?
}

// MARK: - Friend Card

private struct FriendTripCard: View {
    let friend: FriendTrip
    private var operatorColor: Color { ColorTheme.operatorColor(for: friend.trainOperator) }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(operatorColor.opacity(0.2))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(friend.initials)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(operatorColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.rtSubhead)
                    .foregroundStyle(ColorTheme.textPrimary)

                HStack(spacing: 6) {
                    Text(friend.trainOperator)
                        .font(.rtCaption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(operatorColor, in: RoundedRectangle(cornerRadius: 4))

                    Text("\(friend.origin) → \(friend.destination)")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textSecondary)
                }

                if let mins = friend.minutesUntilArrival {
                    Text("Arrives in \(mins) min")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textTertiary)
                }
            }

            Spacer()

            StatusBadge(status: friend.status)
        }
        .padding(16)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Empty State

private struct EmptySocialView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 52))
                .foregroundStyle(ColorTheme.textTertiary)
            Text("No friends yet")
                .font(.rtHeadline)
                .foregroundStyle(ColorTheme.textPrimary)
            Text("Add friends to see their trips in real time.")
                .font(.rtBody)
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                // Add friend
            } label: {
                Label("Add Friend", systemImage: "person.badge.plus")
                    .font(.rtSubhead)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorTheme.accent, in: Capsule())
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SocialView()
}
