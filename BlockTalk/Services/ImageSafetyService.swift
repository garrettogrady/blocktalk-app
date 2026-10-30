import SensitiveContentAnalysis
import UIKit

struct ImageSafetyService {
    enum Result {
        case safe
        case blocked(String)
    }

    private let analyzer = SCSensitivityAnalyzer()

    func check(_ image: UIImage) async -> Result {
        guard analyzer.analysisPolicy != .disabled else { return .safe }
        guard let cgImage = image.cgImage else { return .safe }

        do {
            let response = try await analyzer.analyzeImage(cgImage)
            if response.isSensitive {
                return .blocked("Sensitive content detected")
            }
            return .safe
        } catch {
            return .safe
        }
    }
}
