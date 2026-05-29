import SwiftUI
import SwiftData
import CloudKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    @ObservedObject private var ckService = CloudKitService.shared

    // MARK: - Local Form State
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var isSyncEnabled: Bool = true
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "Personal Profile", icon: "person.crop.circle")
                            FormCard {
                                FormRow(label: "Display Name", icon: "person.fill") {
                                    TextField("e.g. Jane Doe", text: $displayName)
                                        .font(.rtBody)
                                        .foregroundStyle(ColorTheme.textPrimary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider().opacity(0.08).padding(.leading, 52)

                                FormRow(label: "Username", icon: "at") {
                                    TextField("e.g. janedoe", text: $username)
                                        .font(.rtBody)
                                        .foregroundStyle(ColorTheme.textPrimary)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }

                        // Cloud Sync Section
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "Backup & Sync", icon: "icloud")
                            FormCard {
                                Toggle(isOn: $isSyncEnabled) {
                                    FormRow(label: "iCloud Synchronization", icon: "icloud.fill") {
                                        Text(ckService.isSyncEnabled ? "Syncing Automatically" : "Sync Disabled")
                                            .font(.rtCaption)
                                            .foregroundStyle(ColorTheme.textSecondary)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accent))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .onChange(of: isSyncEnabled) { _, newValue in
                                    ckService.isSyncEnabled = newValue
                                }

                                Divider().opacity(0.08).padding(.leading, 52)

                                // Status Row
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(ColorTheme.textTertiary)
                                        .frame(width: 24)
                                    Text("Account Status")
                                        .font(.rtBody)
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    Spacer()
                                    Text(iCloudStatusLabel)
                                        .font(.rtCaption.bold())
                                        .foregroundStyle(iCloudStatusColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(iCloudStatusColor.opacity(0.12), in: Capsule())
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }

                        // Data Management Section
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "Data Management", icon: "exclamationmark.shield")
                            FormCard {
                                Button(role: .destructive) {
                                    showClearConfirm = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(ColorTheme.accentRed)
                                            .frame(width: 24)
                                        Text("Clear Stored Trips")
                                            .font(.rtBody)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(ColorTheme.accentRed)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ColorTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .font(.rtSubhead.bold())
                    .foregroundStyle(ColorTheme.accent)
                }
            }
            .onAppear {
                loadProfile()
            }
            .confirmationDialog(
                "Delete All Trip History?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    clearAllTrips()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all your logged trips from this device and iCloud. This action cannot be undone.")
            }
        }
    }

    // MARK: - Helper Methods

    private func loadProfile() {
        if let user = appState.currentUser {
            displayName = user.displayName
            username = user.username
        }
        isSyncEnabled = ckService.isSyncEnabled
    }

    private func saveProfile() {
        appState.updateProfile(username: username, displayName: displayName)
        dismiss()
    }

    private func clearAllTrips() {
        do {
            // Cancel notification triggers for all trips
            let descriptor = FetchDescriptor<TripRecord>()
            let trips = try modelContext.fetch(descriptor)
            for trip in trips {
                NotificationService.shared.cancelNotifications(for: trip.toTrip())
            }
            
            // Delete all records
            try modelContext.delete(model: TripRecord.self)
            try modelContext.save()
        } catch {
            print("Failed to delete trip records: \(error)")
        }
        dismiss()
    }

    private var iCloudStatusLabel: String {
        switch ckService.accountStatus {
        case .available:
            return "Active"
        case .noAccount:
            return "No Account"
        case .restricted:
            return "Restricted"
        case .couldNotDetermine:
            return "Unknown"
        default:
            return "Unavailable"
        }
    }

    private var iCloudStatusColor: Color {
        switch ckService.accountStatus {
        case .available:
            return ColorTheme.accentGreen
        case .noAccount:
            return ColorTheme.accentAmber
        case .restricted:
            return ColorTheme.accentRed
        default:
            return ColorTheme.textTertiary
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
