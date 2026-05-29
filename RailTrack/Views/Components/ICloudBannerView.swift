import SwiftUI
import CloudKit

struct ICloudBannerView: View {
    @ObservedObject private var ckService = CloudKitService.shared
    @State private var showDetails = false

    private var statusMessage: (title: String, subtitle: String, icon: String) {
        switch ckService.accountStatus {
        case .noAccount:
            return (
                title: "iCloud Sync Offline",
                subtitle: "Sign into iCloud on your device to enable automatic trip backups.",
                icon: "icloud.slash"
            )
        case .restricted:
            return (
                title: "Sync Restricted",
                subtitle: "iCloud access is restricted on this device/account.",
                icon: "exclamationmark.icloud"
            )
        case .couldNotDetermine:
            return (
                title: "iCloud Sync Paused",
                subtitle: "Unable to determine iCloud account status. Check your connection.",
                icon: "exclamationmark.triangle"
            )
        default:
            return (
                title: "iCloud Sync Issues",
                subtitle: "Automatic syncing is temporarily unavailable.",
                icon: "icloud.slash"
            )
        }
    }

    var body: some View {
        if ckService.accountStatus == .available {
            EmptyView()
        } else {
            Button {
                showDetails = true
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(ColorTheme.accentAmber.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: statusMessage.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ColorTheme.accentAmber)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(statusMessage.title)
                            .font(.rtSubhead)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text(statusMessage.subtitle)
                            .font(.rtCaption)
                            .foregroundStyle(ColorTheme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .padding(.top, 12)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ColorTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(ColorTheme.accentAmber.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showDetails) {
                ICloudDetailsSheet()
            }
        }
    }
}

private struct ICloudDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Icon
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(ColorTheme.accentAmber.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "icloud.and.arrow.up")
                                    .font(.system(size: 36))
                                    .foregroundStyle(ColorTheme.accentAmber)
                            }
                            Spacer()
                        }
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Automatic iCloud Sync")
                                .font(.rtTitle)
                                .foregroundStyle(ColorTheme.textPrimary)
                            
                            Text("RailTrack uses SwiftData combined with iCloud (CloudKit) to silently keep your trips safe and synchronized across your Apple devices.")
                                .font(.rtBody)
                                .foregroundStyle(ColorTheme.textSecondary)
                        }

                        Divider().opacity(0.12)

                        // Feature list
                        VStack(alignment: .leading, spacing: 18) {
                            DetailRow(
                                icon: "lock.fill",
                                title: "Private & Secure",
                                description: "All data is securely saved directly in your personal iCloud Private Database. Nobody else — not even the developers — can access it."
                            )
                            DetailRow(
                                icon: "wifi.slash",
                                title: "Full Offline Support",
                                description: "Add or edit trips even when you are offline. They are saved locally immediately and will sync automatically once internet connectivity is restored."
                            )
                            DetailRow(
                                icon: "iphone.and.ipad",
                                title: "Multi-Device Sync",
                                description: "Sign in with the same Apple Account on your iPad or other iPhone, and your entire train history will sync seamlessly."
                            )
                        }

                        Divider().opacity(0.12)

                        // Resolution suggestion
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to resolve this?")
                                .font(.rtHeadline)
                                .foregroundStyle(ColorTheme.textPrimary)
                            Text("Go to your device's Settings, sign into your Apple Account, and verify that iCloud Drive and iCloud Sync are enabled under iCloud settings.")
                                .font(.rtBody)
                                .foregroundStyle(ColorTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.rtSubhead.bold())
                    .foregroundStyle(ColorTheme.accent)
                }
            }
        }
    }
}

private struct DetailRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(ColorTheme.accent)
                .frame(width: 24, height: 24)
                .padding(4)
                .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.rtSubhead)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(description)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        ColorTheme.background.ignoresSafeArea()
        ICloudBannerView()
            .padding()
    }
}
