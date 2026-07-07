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
