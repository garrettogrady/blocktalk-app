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

    /// Vital gym — NW corner of Broome & Clinton (per Matt). Single source of
    /// truth so the map tab and the landing screen always place it identically.
    /// Anchored off Doughnut Plant's verified coordinate (379 Grand, one block
    /// south). Nudge here if it needs to be exact-to-the-door.
    static let vitalCoordinate = CLLocationCoordinate2D(latitude: 40.71715, longitude: -73.98513)

    private static func make(_ id: UUID, _ corner: String, _ lat: Double, _ lng: Double) -> Pin {
        Pin(id: id, userId: UUID(), latitude: lat, longitude: lng,
            cornerName: corner, neighborhoodId: Post.lesNeighborhoodId,
            createdAt: Date().addingTimeInterval(-3600))
    }

    /// A corner that's also tagged to a business — renders house-blue (Route 2).
    private static func makeBiz(_ id: UUID, _ corner: String, _ lat: Double, _ lng: Double,
                                place: String, category: String, symbol: String) -> Pin {
        var pin = make(id, corner, lat, lng)
        pin.placeName = place
        pin.placeCategory = category
        pin.placeSymbol = symbol
        return pin
    }

    static let samples: [Pin] = [
        make(essexRivington, "Essex & Rivington", 40.7196, -73.9878),
        make(stantonNorfolk, "Stanton & Norfolk", 40.7211, -73.9871),
        make(houstonLudlow, "Houston & Ludlow", 40.7222, -73.9877),
        make(delanceyAllen, "Delancey & Allen", 40.7186, -73.9898),
        // The gym street comment — tagged to a business, so it shows house-blue.
        makeBiz(clintonDelancey, "Broome & Clinton", vitalCoordinate.latitude, vitalCoordinate.longitude,
                place: "Vital", category: "gym", symbol: "dumbbell.fill"),
    ]
}
