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
        // Bundled point-in-polygon (no backend): which neighborhood polygon
        // actually contains the GPS coordinate. [PROD-DIFF: PostGIS ST_Contains.]
        let polygons = NeighborhoodPolygonLoader.load()
        guard let match = polygons.first(where: { $0.contains(coordinate) }) else { return nil }
        // Canonical LES carries the stable id the bundled sample data uses.
        if match.name.caseInsensitiveCompare(Neighborhood.les.name) == .orderedSame {
            return .les
        }
        let entry = NeighborhoodDirectory.all.first { $0.name.caseInsensitiveCompare(match.name) == .orderedSame }
        return Neighborhood(
            id: UUID(),
            name: match.name,
            shortCode: entry?.shortCode ?? "NYC",
            borough: entry?.borough ?? ""
        )
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
