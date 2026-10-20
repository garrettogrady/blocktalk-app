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

    /// How far a neighborhood boundary may be overshot and still count as "here".
    /// About one long block. Street corners sit exactly on these lines and GPS
    /// wanders 10 to 30 m, so a zero-tolerance fence blocked people standing on
    /// their own corner. Mirrored server-side in create_pin (00028).
    static let graceMeters: CLLocationDistance = 150

    /// Inside the polygon, or within `graceMeters` of its edge.
    func containsWithGrace(_ coord: CLLocationCoordinate2D, meters: CLLocationDistance = graceMeters) -> Bool {
        contains(coord) || distanceToEdge(coord) <= meters
    }

    /// Shortest distance from a point to any edge of any ring, in meters.
    func distanceToEdge(_ p: CLLocationCoordinate2D) -> CLLocationDistance {
        // Flatten to a local plane: scale longitude by cos(lat) so degrees are
        // roughly isotropic, project onto each segment, measure the real distance.
        let k = cos(p.latitude * .pi / 180)
        var best = CLLocationDistance.greatestFiniteMagnitude
        let here = CLLocation(latitude: p.latitude, longitude: p.longitude)
        for ring in rings where ring.count > 1 {
            for i in 0..<ring.count {
                let a = ring[i], b = ring[(i + 1) % ring.count]
                let ax = a.longitude * k, ay = a.latitude
                let bx = b.longitude * k, by = b.latitude
                let px = p.longitude * k, py = p.latitude
                let dx = bx - ax, dy = by - ay
                let len2 = dx * dx + dy * dy
                let t = len2 == 0 ? 0 : max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / len2))
                let q = CLLocation(latitude: ay + t * dy, longitude: (ax + t * dx) / k)
                best = min(best, here.distance(from: q))
            }
        }
        return best
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
