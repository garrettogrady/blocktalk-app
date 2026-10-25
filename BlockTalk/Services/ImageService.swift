import Foundation
import UIKit

struct ImageService {
    private let bucket = "post-images"

    /// Longest edge a post photo is stored at. Phone cameras produce 4000px+
    /// images; nothing in the app renders wider than a screen.
    static let maxEdge: CGFloat = 1600

    private let safety = ImageSafetyService()

    /// Upload an image to Supabase Storage and return its public URL.
    func upload(image: UIImage, userId: UUID) async throws -> String {
        let safetyResult = await safety.check(image)
        if case .blocked = safetyResult {
            throw ImageError.contentBlocked
        }
        guard let data = Self.downscaled(image).jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }
        let path = "\(userId.uuidString)/\(UUID().uuidString).jpg"
        try await supabase.storage
            .from(bucket)
            .upload(path, data: data, options: .init(contentType: "image/jpeg"))
        let publicURL = try supabase.storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }

    /// Scale so the longest edge is at most `maxEdge`; smaller images pass through.
    static func downscaled(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxEdge else { return image }
        let scale = maxEdge / longest
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    func delete(path: String) async throws {
        try await supabase.storage
            .from(bucket)
            .remove(paths: [path])
    }

    enum ImageError: LocalizedError {
        case compressionFailed
        case contentBlocked

        var errorDescription: String? {
            switch self {
            case .compressionFailed: "Failed to compress image"
            case .contentBlocked: "This image can't be posted because it may violate our content guidelines."
            }
        }
    }
}
