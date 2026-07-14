import Foundation
import UIKit

struct ImageService {
    private let bucket = "post-images"

    /// Bundled-mock: write the attached image to a temp file and return its
    /// file:// URL so AsyncImage can render it locally (no backend storage).
    /// [PROD-DIFF: restore the supabase.storage upload for the real build.]
    func upload(image: UIImage, userId: UUID) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: url)
        return url.absoluteString
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
