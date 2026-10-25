import CoreImage
import Vision
import UIKit

struct ImageSafetyService {
    enum Result {
        case safe
        case blocked(String)
    }

    func check(_ image: UIImage) async -> Result {
        guard let cgImage = image.cgImage else { return .safe }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: .safe)
                    return
                }

                for obs in observations {
                    let id = obs.identifier.lowercased()
                    let isExplicit = id.contains("nsfw") ||
                                     id.contains("explicit") ||
                                     id.contains("nude") ||
                                     id.contains("sexual") ||
                                     id.contains("porn")
                    if isExplicit && obs.confidence > 0.7 {
                        continuation.resume(returning: .blocked(obs.identifier))
                        return
                    }
                }

                continuation.resume(returning: .safe)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: .safe)
            }
        }
    }
}
