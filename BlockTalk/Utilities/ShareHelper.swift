import UIKit

enum ShareHelper {
    static func sharePost(_ post: Post) {
        let url = "https://blocktalk.nyc/p/\(post.id.uuidString)"
        present(items: ["\(post.text)\n\n\(url)", URL(string: url)!])
    }

    /// Share raw text only (used by the discarded-post "copy text" action).
    static func shareText(_ text: String) {
        present(items: [text])
    }

    private static func present(items: [Any]) {
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController
        else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        activityController.popoverPresentationController?.sourceView = topVC.view
        topVC.present(activityController, animated: true)
    }
}
