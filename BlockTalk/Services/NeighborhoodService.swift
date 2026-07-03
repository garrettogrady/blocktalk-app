import Foundation
import CoreLocation

struct NeighborhoodService {
    func fetchAll() async throws -> [Neighborhood] {
        try await supabase.from("neighborhoods")
            .select("id, name, short_code, borough")
            .order("borough")
            .order("name")
            .execute()
            .value
    }

    func findNeighborhood(at coordinate: CLLocationCoordinate2D) async throws -> Neighborhood? {
        // Uses PostGIS ST_Contains to find which neighborhood polygon contains the point
        let result: [Neighborhood] = try await supabase.rpc(
            "find_neighborhood",
            params: [
                "lat": coordinate.latitude,
                "lng": coordinate.longitude,
            ]
        ).execute().value

        return result.first
    }

    func fetchPolygon(neighborhoodId: UUID) async throws -> [[CLLocationCoordinate2D]] {
        // Fetch GeoJSON representation of the polygon
        struct GeoResult: Decodable {
            let geojson: String
        }

        let result: [GeoResult] = try await supabase.rpc(
            "neighborhood_geojson",
            params: ["nid": neighborhoodId.uuidString]
        ).execute().value

        guard let first = result.first else { return [] }
        return GeoJSONParser.parseCoordinates(from: first.geojson)
    }
}
