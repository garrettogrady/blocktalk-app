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
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Bundled mock pins (the 5 LES corners)
extension Pin {
    static let essexRivington = UUID(uuidString: "c0000000-0000-0000-0000-000000000001")!
    static let stantonNorfolk = UUID(uuidString: "c0000000-0000-0000-0000-000000000002")!
    static let houstonLudlow  = UUID(uuidString: "c0000000-0000-0000-0000-000000000003")!
    static let delanceyAllen  = UUID(uuidString: "c0000000-0000-0000-0000-000000000004")!
    static let clintonDelancey = UUID(uuidString: "c0000000-0000-0000-0000-000000000005")!

    /// VITAL Climbing Gym — 182 Broome St, NW corner of Broome & Clinton.
    /// Verified via OpenStreetMap's geocoder (not estimated). Single source of
    /// truth for both the map tab and the landing screen.
    static let vitalCoordinate = CLLocationCoordinate2D(latitude: 40.71705, longitude: -73.98634)

    private static func make(_ id: UUID, _ corner: String, _ lat: Double, _ lng: Double) -> Pin {
        Pin(id: id, userId: UUID(), latitude: lat, longitude: lng,
            cornerName: corner, neighborhoodId: Post.lesNeighborhoodId,
            createdAt: Date().addingTimeInterval(-3600))
    }

    /// A corner that's also tagged to a business — renders house-blue (Route 2).
    /// The icon is derived from the category, not passed in per call site, so the
    /// same category always yields the same glyph everywhere it's shown.
    private static func makeBiz(_ id: UUID, _ corner: String, _ lat: Double, _ lng: Double,
                                place: String, category: String) -> Pin {
        var pin = make(id, corner, lat, lng)
        pin.placeName = place
        pin.placeCategory = category
        pin.placeSymbol = symbol(forCategory: category)
        return pin
    }

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

    /// The Vital gym street-comment pin — ONE definition, referenced by the map
    /// samples and the landing screen so the location + icon can never drift.
    static let vital: Pin = makeBiz(clintonDelancey, "Broome & Clinton",
                                    vitalCoordinate.latitude, vitalCoordinate.longitude,
                                    place: "Vital", category: "gym")

    static let samples: [Pin] = [
        make(essexRivington, "Essex & Rivington", 40.7196, -73.9878),
        make(stantonNorfolk, "Stanton & Norfolk", 40.7211, -73.9871),
        make(houstonLudlow, "Houston & Ludlow", 40.7222, -73.9877),
        make(delanceyAllen, "Delancey & Allen", 40.7186, -73.9898),
        vital,
    ]
}
