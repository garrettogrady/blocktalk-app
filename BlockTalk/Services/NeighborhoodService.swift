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
        // Bundled point-in-polygon: which neighborhood polygon actually contains
        // the GPS coordinate. [PROD-DIFF: PostGIS ST_Contains.]
        let polygons = NeighborhoodPolygonLoader.load()
        guard let match = polygons.first(where: { $0.contains(coordinate) }) else { return nil }
        // Look up the real neighborhood from Supabase so the ID matches posts.
        return try await fetchByName(match.name)
    }

    func fetchByName(_ name: String) async throws -> Neighborhood? {
        let results: [Neighborhood] = try await supabase.from("neighborhoods")
            .select("id, name, short_code, borough")
            .eq("name", value: name)
            .limit(1)
            .execute()
            .value
        return results.first
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
