import CoreLocation
import MapKit

/// Lightweight polygon data parsed from neighborhood-polygons.json
struct NeighborhoodPolygon: Identifiable {
    let id = UUID()
    let name: String
    let rings: [[CLLocationCoordinate2D]]

    /// All rings as MKPolygon objects for MapKit rendering
    var mkPolygons: [MKPolygon] {
        rings.map { MKPolygon(coordinates: $0, count: $0.count) }
    }

    /// Label centroid — average of ALL points across ALL rings (matches Expo's
    /// centroidOf). Averaging only the first ring put the label on a tiny
    /// detached piece (LES's label drifted toward the river/Brooklyn).
    var center: CLLocationCoordinate2D {
        var lat = 0.0, lng = 0.0, n = 0
        for ring in rings {
            for p in ring { lat += p.latitude; lng += p.longitude; n += 1 }
        }
        guard n > 0 else { return CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) }
        return CLLocationCoordinate2D(latitude: lat / Double(n), longitude: lng / Double(n))
    }

    /// Ray-casting point-in-polygon over any ring (used for the pin-drop geofence)
    func contains(_ coord: CLLocationCoordinate2D) -> Bool {
        rings.contains { Self.pointInRing(coord, $0) }
    }

    static func pointInRing(_ p: CLLocationCoordinate2D, _ ring: [CLLocationCoordinate2D]) -> Bool {
        guard ring.count > 2 else { return false }
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let (xi, yi) = (ring[i].longitude, ring[i].latitude)
            let (xj, yj) = (ring[j].longitude, ring[j].latitude)
            if ((yi > p.latitude) != (yj > p.latitude)) &&
                (p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}

enum NeighborhoodPolygonLoader {
    private static var cache: [NeighborhoodPolygon]?

    /// Load all neighborhood polygons from the bundled JSON — parsed once, then cached
    /// (so it never re-parses, and never runs on the app-launch critical path).
    static func load() -> [NeighborhoodPolygon] {
        if let cache { return cache }
        let result = parse()
        cache = result
        return result
    }

    private static func parse() -> [NeighborhoodPolygon] {
        guard let url = Bundle.main.url(forResource: "neighborhood-polygons", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load neighborhood-polygons.json")
            return []
        }

        // Parse the compact JSON: [{"name":"...","rings":[[[lng,lat],...],...]}]
        guard let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("Failed to parse neighborhood-polygons.json")
            return []
        }

        return entries.compactMap { entry -> NeighborhoodPolygon? in
            guard let name = entry["name"] as? String,
                  let ringsData = entry["rings"] as? [[[Double]]] else {
                return nil
            }

            let rings: [[CLLocationCoordinate2D]] = ringsData.map { ring in
                ring.map { point in
                    // JSON is [lng, lat] (GeoJSON convention)
                    CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                }
            }

            // Drop tiny detached slivers (NTA artifacts) — keep the main shape
            // + any genuinely large secondary part. Otherwise LES etc. render a
            // confusing disconnected fragment near the waterfront.
            let maxCount = rings.map(\.count).max() ?? 0
            let threshold = max(4, Int(Double(maxCount) * 0.3))
            let kept = rings.filter { $0.count >= threshold }

            guard !kept.isEmpty else { return nil }
            return NeighborhoodPolygon(name: name, rings: kept)
        }
    }
}
