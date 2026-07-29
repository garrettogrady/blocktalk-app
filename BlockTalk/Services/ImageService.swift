import Foundation
import UIKit

struct ImageService {
    private let bucket = "post-images"

    /// Upload an image to Supabase Storage and return its public URL.
    func upload(image: UIImage, userId: UUID) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }
        let path = "\(userId.uuidString)/\(UUID().uuidString).jpg"
        try await supabase.storage
            .from(bucket)
            .upload(path, data: data, options: .init(contentType: "image/jpeg"))
        let publicURL = try supabase.storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }

    func delete(path: String) async throws {
        try await supabase.storage
            .from(bucket)
            .remove(paths: [path])
    }

    enum ImageError: LocalizedError {
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .compressionFailed: "Failed to compress image"
            }
        }
    }
}
