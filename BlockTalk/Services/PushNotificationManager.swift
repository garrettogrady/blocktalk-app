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

    private var deviceTokenHex: String?
    private let tokenService = DeviceTokenService()

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.permissionState = granted ? .granted : .denied
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    Analytics.pushPermissionGranted()
                } else {
                    Analytics.pushPermissionDenied()
                }
            }
        }
    }

    func didRegisterToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        deviceTokenHex = hex
    }

    func saveToken(userId: UUID) {
        guard let hex = deviceTokenHex else { return }
        #if DEBUG
        let sandbox = true
        #else
        let sandbox = false
        #endif
        Task {
            do {
                try await tokenService.register(userId: userId, token: hex, sandbox: sandbox)
            } catch {
                print("[Push] Failed to save device token: \(error)")
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
