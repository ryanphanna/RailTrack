import Foundation
import CloudKit
import Combine

@MainActor
final class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSyncEnabled: Bool = true

    private init() {
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
        do {
            let status = try await CKContainer.default().accountStatus()
            self.accountStatus = status
        } catch {
            self.accountStatus = .couldNotDetermine
        }
    }
}
