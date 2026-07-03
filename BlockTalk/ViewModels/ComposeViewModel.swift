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

    func submit(userId: UUID, neighborhoodId: UUID, pinId: UUID? = nil) async -> Post? {
        guard canSubmit else { return nil }
        isSubmitting = true

        do {
            var imageUrl: String?
            if let image = selectedImage {
                imageUrl = try await imageService.upload(image: image, userId: userId)
            }

            let newPost = NewPost(
                userId: userId,
                neighborhoodId: neighborhoodId,
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                imageUrl: imageUrl,
                pinId: pinId,
                isDailyPrompt: isDailyPrompt
            )

            let post = try await postService.createPost(newPost)
            isSubmitting = false
            return post
        } catch {
            self.error = error.localizedDescription
            isSubmitting = false
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
