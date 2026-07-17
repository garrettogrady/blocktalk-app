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

    private static func make(_ id: UUID, _ corner: String, _ lat: Double, _ lng: Double) -> Pin {
        Pin(id: id, userId: UUID(), latitude: lat, longitude: lng,
            cornerName: corner, neighborhoodId: Post.lesNeighborhoodId,
            createdAt: Date().addingTimeInterval(-3600))
    }

    static let samples: [Pin] = [
        make(essexRivington, "Essex & Rivington", 40.7196, -73.9878),
        make(stantonNorfolk, "Stanton & Norfolk", 40.7211, -73.9871),
        make(houstonLudlow, "Houston & Ludlow", 40.7222, -73.9877),
        make(delanceyAllen, "Delancey & Allen", 40.7186, -73.9898),
        make(clintonDelancey, "Clinton & Delancey", 40.7181, -73.9862),
    ]
}
