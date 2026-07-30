import Foundation
import CoreLocation

struct Pin: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let latitude: Double
    let longitude: Double
    var cornerName: String?
    let neighborhoodId: UUID
    var createdAt: Date?

    // Optional business the comment is tagged to (from Apple Maps POI at post
    // time). [PROD-DIFF: Apple's terms forbid warehousing their place database —
    // store a neutral place key + re-fetch display data live for production.]
    var placeName: String? = nil
    var placeCategory: String? = nil
    var placeSymbol: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case latitude, longitude
        case cornerName = "corner_name"
        case neighborhoodId = "neighborhood_id"
        case createdAt = "created_at"
        case placeName = "place_name"
        case placeCategory = "place_category"
        case placeSymbol = "place_symbol"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Category → SF Symbol mapping
extension Pin {
    /// Category → SF Symbol, so a business's icon is data-driven, not hardcoded
    /// at each place it appears (map / feed chip / landing all resolve the same).
    static func symbol(forCategory category: String) -> String {
        switch category.lowercased() {
        case "gym", "fitness":     return "dumbbell.fill"
        case "restaurant":         return "fork.knife"
        case "cafe", "café":       return "cup.and.saucer.fill"
        case "bakery":             return "birthday.cake.fill"
        case "bar", "nightlife":   return "wineglass.fill"
        case "museum":             return "building.columns.fill"
        case "market":             return "cart.fill"
        case "pharmacy":           return "cross.case.fill"
        default:                   return "mappin.circle.fill"
        }
    }
}
