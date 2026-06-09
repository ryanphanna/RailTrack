import Foundation
import CloudKit
import Combine

@MainActor
final class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isDevelopmentMode: Bool = false
    @Published var isSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: "isSyncEnabled")
        }
    }

    private init() {
        #if DEBUG
        self.isDevelopmentMode = true
        #endif
        
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
        // CKContainer.default() requires the CloudKit entitlement, which is not
        // enabled for the current personal-team build target. Skip the API call
        // to avoid an EXC_BREAKPOINT assertion trap on device. The status
        // defaults to .couldNotDetermine, which the UI handles gracefully.
        guard FileManager.default.ubiquityIdentityToken != nil else {
            self.accountStatus = .noAccount
            return
        }
        self.accountStatus = .couldNotDetermine
    }
}
