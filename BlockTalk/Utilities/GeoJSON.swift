import CoreLocation
import Foundation

enum GeoJSONParser {
    struct FeatureCollection: Decodable {
        let type: String
        let features: [Feature]
    }

    struct Feature: Decodable {
        let type: String
        let properties: [String: AnyCodable]?
        let geometry: Geometry
    }

    struct Geometry: Decodable {
        let type: String
        let coordinates: AnyCodable
    }

    struct AnyCodable: Decodable {
        let value: Any

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let string = try? container.decode(String.self) {
                value = string
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if let array = try? container.decode([AnyCodable].self) {
                value = array.map(\.value)
            } else if let dict = try? container.decode([String: AnyCodable].self) {
                value = dict.mapValues(\.value)
            } else {
                value = NSNull()
            }
        }
    }

    static func parseCoordinates(from geoJSON: String) -> [[CLLocationCoordinate2D]] {
        guard let data = geoJSON.data(using: .utf8) else { return [] }
        return parseCoordinates(from: data)
    }

    static func parseCoordinates(from data: Data) -> [[CLLocationCoordinate2D]] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String,
              let coordinates = json["coordinates"]
        else { return [] }

        switch type {
        case "Polygon":
            return parsePolygon(coordinates)
        case "MultiPolygon":
            return parseMultiPolygon(coordinates)
        default:
            return []
        }
    }

    static func loadFeatureCollection(from url: URL) -> FeatureCollection? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(FeatureCollection.self, from: data)
    }

    private static func parsePolygon(_ coordinates: Any) -> [[CLLocationCoordinate2D]] {
        guard let rings = coordinates as? [[[Double]]] else { return [] }
        return rings.map { ring in
            ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        }
    }

    private static func parseMultiPolygon(_ coordinates: Any) -> [[CLLocationCoordinate2D]] {
        guard let polygons = coordinates as? [[[[Double]]]] else { return [] }
        return polygons.flatMap { polygon in
            polygon.map { ring in
                ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            }
        }
    }
}
