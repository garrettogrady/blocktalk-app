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
