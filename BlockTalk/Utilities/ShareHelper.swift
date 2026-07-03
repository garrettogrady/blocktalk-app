import UIKit

enum ShareHelper {
    static func sharePost(_ post: Post) {
        let url = "https://blocktalk.nyc/p/\(post.id.uuidString)"
        let text = "\(post.text)\n\n\(url)"

        let activityController = UIActivityViewController(
            activityItems: [text, URL(string: url)!],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController
        else { return }

        // Find the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        activityController.popoverPresentationController?.sourceView = topVC.view
        topVC.present(activityController, animated: true)
    }
}
