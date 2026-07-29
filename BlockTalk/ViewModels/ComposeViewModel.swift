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

    /// Creates a post via Supabase. Uploads the image first if present,
    /// then inserts the post row.
    func submit(userId: UUID, neighborhoodId: UUID, author: PostAuthor?, pinId: UUID? = nil, dailyPromptId: UUID? = nil) async -> Post? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }

        var imageUrl: String?
        if let image = selectedImage {
            imageUrl = try? await imageService.upload(image: image, userId: userId)
        }

        let newPost = NewPost(
            userId: userId,
            neighborhoodId: neighborhoodId,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageUrl,
            pinId: pinId,
            isDailyPrompt: isDailyPrompt,
            dailyPromptId: dailyPromptId
        )

        do {
            let post = try await postService.createPost(newPost)
            return post
        } catch {
            self.error = error.localizedDescription
            return nil
        }
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
