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

    /// Bundled polygon names that differ from the Supabase neighborhood name by
    /// actual words (casing is already handled by the case-insensitive lookup).
    /// Without this, a user standing there resolves to nothing and gets stuck on
    /// "finding your neighborhood…". Verified list: only "Flatiron District" today.
    private static let polygonNameAliases: [String: String] = [
        "Flatiron District": "Flatiron",
    ]

    func findNeighborhood(at coordinate: CLLocationCoordinate2D) async throws -> Neighborhood? {
        // Bundled point-in-polygon: which neighborhood polygon actually contains
        // the GPS coordinate. [PROD-DIFF: PostGIS ST_Contains.]
        let polygons = NeighborhoodPolygonLoader.load()
        guard let match = polygons.first(where: { $0.contains(coordinate) }) else { return nil }
        // Look up the real neighborhood from Supabase so the ID matches posts,
        // translating any polygon→DB name difference first.
        let name = Self.polygonNameAliases[match.name] ?? match.name
        return try await fetchByName(name)
    }

    func fetchByName(_ name: String) async throws -> Neighborhood? {
        // Case-INSENSITIVE match: the bundled polygon names and the Supabase table
        // names differ in casing for some neighborhoods (e.g. polygon "Nolita" vs
        // table "NoLita"). A case-sensitive .eq returned zero rows, so the neighborhood
        // never resolved and the app got stuck on "finding your neighborhood…".
        // ilike with no % / _ wildcards is a full-string, case-insensitive equality.
        let results: [Neighborhood] = try await supabase.from("neighborhoods")
            .select("id, name, short_code, borough")
            .ilike("name", value: name)
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
