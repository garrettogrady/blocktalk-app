import Foundation
import CoreLocation

struct CreatePinParams: Encodable {
    let p_user_id: String
    let p_lat: Double
    let p_lng: Double
    let p_corner_name: String?
    let p_neighborhood_id: String
    let p_place_name: String?
    let p_place_category: String?
    let p_place_symbol: String?
}

struct PinService {
    func createPin(userId: UUID, coordinate: CLLocationCoordinate2D, cornerName: String?, neighborhoodId: UUID,
                   placeName: String? = nil, placeCategory: String? = nil, placeSymbol: String? = nil) async throws -> Pin {
        let params = CreatePinParams(
            p_user_id: userId.uuidString,
            p_lat: coordinate.latitude,
            p_lng: coordinate.longitude,
            p_corner_name: cornerName,
            p_neighborhood_id: neighborhoodId.uuidString,
            p_place_name: placeName,
            p_place_category: placeCategory,
            p_place_symbol: placeSymbol
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
        try await supabase.from("pins_with_coords")
            .select()
            .eq("neighborhood_id", value: neighborhoodId.uuidString)
            .execute()
            .value
    }

    func fetchAllPins() async throws -> [Pin] {
        try await supabase.from("pins_with_coords")
            .select()
            .execute()
            .value
    }

    /// Fetch a specific set of pins by id — used to resolve the corner/coords for
    /// street comments shown in a feed/search/trending list, regardless of which
    /// neighborhood they belong to.
    func fetchPins(ids: [UUID]) async throws -> [Pin] {
        guard !ids.isEmpty else { return [] }
        return try await supabase.from("pins_with_coords")
            .select()
            .in("id", values: ids.map(\.uuidString))
            .execute()
            .value
    }
}
