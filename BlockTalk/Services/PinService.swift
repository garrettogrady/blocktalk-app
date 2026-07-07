import Foundation
import CoreLocation

struct CreatePinParams: Encodable {
    let p_user_id: String
    let p_lat: Double
    let p_lng: Double
    let p_corner_name: String?
    let p_neighborhood_id: String
}

struct PinService {
    func createPin(userId: UUID, coordinate: CLLocationCoordinate2D, cornerName: String?, neighborhoodId: UUID) async throws -> Pin {
        let params = CreatePinParams(
            p_user_id: userId.uuidString,
            p_lat: coordinate.latitude,
            p_lng: coordinate.longitude,
            p_corner_name: cornerName,
            p_neighborhood_id: neighborhoodId.uuidString
        )

        let pins: [Pin] = try await supabase.rpc("create_pin", params: params)
            .execute()
            .value

        guard let pin = pins.first else {
            throw NSError(domain: "PinService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Pin creation returned no results"])
        }
        return pin
    }

    func fetchNearbyPins(coordinate: CLLocationCoordinate2D, radiusMeters: Double = 1000, neighborhoodId: UUID) async throws -> [Pin] {
        try await supabase.from("pins_with_coords")
            .select()
            .eq("neighborhood_id", value: neighborhoodId.uuidString)
            .execute()
            .value
    }

    func fetchPinsForNeighborhood(_ neighborhoodId: UUID) async throws -> [Pin] {
        Pin.samples   // bundled mock data
    }

    func fetchAllPins() async throws -> [Pin] {
        Pin.samples   // bundled mock data
    }
}
