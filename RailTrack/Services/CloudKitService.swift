import Foundation
import CloudKit
import Combine

@MainActor
final class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: "isSyncEnabled")
        }
    }

    private init() {
        self.isSyncEnabled = UserDefaults.standard.object(forKey: "isSyncEnabled") as? Bool ?? true
        Task {
            await checkAccountStatus()
        }
        // Listen for iCloud account changes on device
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudAccountDidChange),
            name: .CKAccountChanged,
            object: nil
        )
    }

    @objc private func iCloudAccountDidChange() {
        Task {
            await checkAccountStatus()
        }
    }

    func checkAccountStatus() async {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            self.accountStatus = .noAccount
            return
        }
        do {
            let status = try await CKContainer.default().accountStatus()
            self.accountStatus = status
        } catch {
            self.accountStatus = .couldNotDetermine
        }
    }
}
