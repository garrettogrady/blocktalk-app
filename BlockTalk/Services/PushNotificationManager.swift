import Foundation
import UIKit
import UserNotifications

enum PushPermissionState {
    case undetermined, granted, denied
}

@Observable
final class PushNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    var permissionState: PushPermissionState = .undetermined
    var showSoftAsk = false
    var currentUserId: UUID?
    /// Set by BlockTalkApp so push taps can navigate directly without NotificationCenter timing issues.
    weak var appState: AppState? {
        didSet { deliverPendingNavigation() }
    }

    private(set) var hasToken: Bool = false
    private var deviceTokenHex: String?
    private let tokenService = DeviceTokenService()
    private var pendingPostId: UUID?
    private var pendingAuthority = false

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("[Push] checkPermission: authorizationStatus = \(settings.authorizationStatus.rawValue)")
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.permissionState = .granted
                case .denied:
                    self.permissionState = .denied
                case .notDetermined:
                    self.permissionState = .undetermined
                @unknown default:
                    self.permissionState = .undetermined
                }
            }
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("[Push] requestAuthorization result: granted=\(granted) error=\(error?.localizedDescription ?? "none")")
            DispatchQueue.main.async {
                self.permissionState = granted ? .granted : .denied
                if granted {
                    Analytics.pushPermissionGranted()
                    // Retry registration at staggered intervals after permission grant
                    for delay in [0.5, 2.0, 5.0, 10.0] {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            if self.hasToken { return }
                            print("[Push] Calling registerForRemoteNotifications() (post-permission, \(delay)s)")
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                } else {
                    Analytics.pushPermissionDenied()
                }
            }
        }
    }

    func didRegisterToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        deviceTokenHex = hex
        hasToken = true
        print("[Push] didRegisterToken: \(hex.prefix(16))… currentUserId=\(currentUserId?.uuidString.prefix(8) ?? "nil")")
        if let userId = currentUserId {
            saveToken(userId: userId)
        } else {
            print("[Push] ⚠️ Token captured but no userId yet — will save when userId is set")
        }
    }

    func saveToken(userId: UUID) {
        guard let hex = deviceTokenHex else {
            print("[Push] saveToken called but no token captured yet")
            return
        }
        #if DEBUG
        let sandbox = true
        #else
        let sandbox = false
        #endif
        print("[Push] Saving token \(hex.prefix(16))… for user \(userId.uuidString.prefix(8))… sandbox=\(sandbox)")
        Task {
            do {
                try await tokenService.register(userId: userId, token: hex, sandbox: sandbox)
                print("[Push] ✅ Token saved to Supabase successfully")
            } catch {
                print("[Push] ❌ Failed to save device token: \(error)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + sound for foreground notifications
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("[Push] didReceive notification tap — userInfo keys: \(userInfo.keys)")
        if userInfo["kind"] as? String == "authority" {
            if let state = appState {
                Task { @MainActor in
                    state.selectedTab = 3
                    state.showAuthorityPage = true
                }
            } else {
                print("[Push] appState nil on authority tap — deferring")
                pendingAuthority = true
            }
            completionHandler()
            return
        }
        if let postIdString = userInfo["post_id"] as? String,
           let postId = UUID(uuidString: postIdString) {
            print("[Push] post_id=\(postIdString) appState=\(appState == nil ? "nil" : "set")")
            if let state = appState {
                navigateToPost(postId, appState: state)
            } else {
                print("[Push] appState nil — stashing postId for later")
                pendingPostId = postId
            }
        }
        completionHandler()
    }

    private func navigateToPost(_ postId: UUID, appState state: AppState) {
        Task {
            let postService = PostService()
            if let post = try? await postService.fetchPost(id: postId) {
                await MainActor.run {
                    state.openedPost = post
                }
            } else {
                print("[Push] ⚠️ Failed to fetch post \(postId)")
            }
        }
    }

    private func deliverPendingNavigation() {
        guard let state = appState else { return }
        if let postId = pendingPostId {
            print("[Push] Delivering deferred navigation to post \(postId)")
            pendingPostId = nil
            navigateToPost(postId, appState: state)
        }
        if pendingAuthority {
            print("[Push] Delivering deferred authority navigation")
            pendingAuthority = false
            Task { @MainActor in
                state.selectedTab = 3
                state.showAuthorityPage = true
            }
        }
    }
}

let pushManager = PushNotificationManager()
