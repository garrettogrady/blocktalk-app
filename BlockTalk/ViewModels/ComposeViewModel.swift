import Foundation
import PhotosUI
import SwiftUI

@Observable
final class ComposeViewModel {
    var text = ""
    var selectedImage: UIImage?
    var isSubmitting = false
    var error: String?
    var pinLocation: CLLocationCoordinate2D?
    var cornerName: String?
    var isNYCWide = false
    var isDailyPrompt = false

    static let postLimit = 1500
    static let postWarnAt = 1050

    var characterCount: Int { text.count }
    var isOverLimit: Bool { characterCount > Self.postLimit }
    var showCounter: Bool { characterCount >= Self.postWarnAt }

    var hateSpeechDetected: Bool {
        LanguageCheck.containsHateSpeech(text)
    }

    var canSubmit: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isOverLimit && !hateSpeechDetected && !isSubmitting
    }

    private let postService = PostService()
    private let imageService = ImageService()

    /// Builds the post locally (bundled-mock: no backend). The caller stashes it
    /// in LocalContentStore so it shows in the feed/map for the session.
    /// [PROD-DIFF: swap back to postService.createPost for the Supabase write.]
    func submit(userId: UUID, neighborhoodId: UUID, author: PostAuthor?, pinId: UUID? = nil) async -> Post? {
        guard canSubmit else { return nil }
        isSubmitting = true

        // Best-effort image handling; nil if it can't be stored locally.
        var imageUrl: String?
        if let image = selectedImage {
            imageUrl = try? await imageService.upload(image: image, userId: userId)
        }

        let post = Post(
            id: UUID(),
            userId: userId,
            neighborhoodId: neighborhoodId,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageUrl,
            pinId: pinId,
            isDailyPrompt: isDailyPrompt,
            score: 0,
            replyCount: 0,
            reportCount: 0,
            status: .live,
            createdAt: Date(),
            author: author
        )
        isSubmitting = false
        return post
    }

    func reset() {
        text = ""
        selectedImage = nil
        pinLocation = nil
        cornerName = nil
        isNYCWide = false
        isDailyPrompt = false
        error = nil
    }
}
