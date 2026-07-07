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

    /// Center point (average of all coordinates in the first ring)
    var center: CLLocationCoordinate2D {
        guard let ring = rings.first, !ring.isEmpty else {
            return CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        }
        let lat = ring.map(\.latitude).reduce(0, +) / Double(ring.count)
        let lng = ring.map(\.longitude).reduce(0, +) / Double(ring.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
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

    /// Meters from `coord` to the nearest polygon edge; 0 when inside. Used to
    /// add a tolerance buffer to the pin-drop geofence, since the bundled
    /// polygons are simplified and a hard inside/outside test is brittle at
    /// borders (a point truly inside LES can fall just outside the simplified
    /// outline). Planar approximation — fine at neighborhood scale.
    func distanceToEdge(_ coord: CLLocationCoordinate2D) -> Double {
        if contains(coord) { return 0 }
        let latM = 111_320.0
        let lngM = 111_320.0 * cos(coord.latitude * .pi / 180)
        func toXY(_ c: CLLocationCoordinate2D) -> (Double, Double) {
            ((c.longitude - coord.longitude) * lngM, (c.latitude - coord.latitude) * latM)
        }
        var best = Double.greatestFiniteMagnitude
        for ring in rings where ring.count > 1 {
            for i in 0..<ring.count {
                let a = toXY(ring[i])
                let b = toXY(ring[(i + 1) % ring.count])
                best = min(best, Self.pointSegmentDistance((0, 0), a, b))
            }
        }
        return best
    }

    private static func pointSegmentDistance(_ p: (Double, Double), _ a: (Double, Double), _ b: (Double, Double)) -> Double {
        let dx = b.0 - a.0, dy = b.1 - a.1
        let len2 = dx * dx + dy * dy
        if len2 == 0 { return hypot(p.0 - a.0, p.1 - a.1) }
        var t = ((p.0 - a.0) * dx + (p.1 - a.1) * dy) / len2
        t = max(0, min(1, t))
        return hypot(p.0 - (a.0 + t * dx), p.1 - (a.1 + t * dy))
    }
}

enum NeighborhoodPolygonLoader {
    /// Load all neighborhood polygons from the bundled JSON
    static func load() -> [NeighborhoodPolygon] {
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

            guard !rings.isEmpty else { return nil }
            return NeighborhoodPolygon(name: name, rings: rings)
        }
    }
}
