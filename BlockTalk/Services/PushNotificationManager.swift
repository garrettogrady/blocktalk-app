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

    private var deviceTokenHex: String?
    private let tokenService = DeviceTokenService()

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
                    // Delay slightly so iOS processes the registration on a fresh run loop
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("[Push] Calling registerForRemoteNotifications() after permission grant (delayed)")
                        UIApplication.shared.registerForRemoteNotifications()
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
        if let postIdString = userInfo["post_id"] as? String,
           let postId = UUID(uuidString: postIdString) {
            Task {
                let postService = PostService()
                if let post = try? await postService.fetchPost(id: postId) {
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .pushNotificationTapped,
                            object: nil,
                            userInfo: ["post": post]
                        )
                    }
                }
            }
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
}

let pushManager = PushNotificationManager()
