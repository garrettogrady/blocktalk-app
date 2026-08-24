import Foundation
import MapKit

@Observable
final class MapViewModel {
    var pins: [Pin] = []
    /// pinId → raw activity score (replies×2 + votes) driving the live pulse.
    var pinActivity: [UUID: Int] = [:]
    var neighborhoods: [Neighborhood] = []
    var isLoading = false
    var error: String?
    var isDropMode = false
    var dropCenter: CLLocationCoordinate2D?
    var radiusMiles: Double = 0.5
    var talkingCounts: [String: Int] = [:]

    // NYC center
    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7193, longitude: -73.9911),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.024)
    )

    private let pinService = PinService()
    private let postService = PostService()
    private let neighborhoodService = NeighborhoodService()

    func loadPins(neighborhoodId: UUID) async {
        do {
            pins = try await pinService.fetchPinsForNeighborhood(neighborhoodId)
            await loadPinActivity()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAllPins() async {
        do {
            pins = try await pinService.fetchAllPins()
            await loadPinActivity()
        } catch {
            self.error = error.localizedDescription
            print("Failed to load pins: \(error)")
        }
    }

    /// Pull reply/vote activity for the current pins so each pulses to its heat.
    func loadPinActivity() async {
        guard !pins.isEmpty else { pinActivity = [:]; return }
        do {
            pinActivity = try await postService.fetchPinActivity(pinIds: pins.map(\.id))
        } catch {
            print("Failed to load pin activity: \(error)")
        }
    }

    /// Raw activity → 0…1 pulse intensity: √(A / 20), capped. 0 activity = no pulse.
    func intensity(forPinId id: UUID) -> Double {
        let a = Double(pinActivity[id] ?? 0)
        guard a > 0 else { return 0 }
        return min((a / 20).squareRoot(), 1)
    }

    func loadNeighborhoods() async {
        do {
            neighborhoods = try await neighborhoodService.fetchAll()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func enterDropMode() {
        isDropMode = true
        dropCenter = region.center
    }

    func cancelDrop() {
        isDropMode = false
        dropCenter = nil
    }

    func updateRadius(from region: MKCoordinateRegion) {
        let latMiles = region.span.latitudeDelta * 69.0 / 2.0
        let lngMiles = region.span.longitudeDelta * 69.0 * cos(region.center.latitude * .pi / 180) / 2.0
        radiusMiles = min(latMiles, lngMiles)
    }

    func loadTalkingCount(name: String) async {
        do {
            guard let neighborhood = neighborhoods.first(where: { $0.name == name }) else { return }
            let count: Int = try await supabase.rpc("neighborhood_talking", params: ["nid": neighborhood.id.uuidString])
                .execute()
                .value
            talkingCounts[name] = count
        } catch {
            print("Failed to load talking count for \(name): \(error)")
            talkingCounts[name] = 0
        }
    }

    func formatRadius() -> String {
        if radiusMiles >= 10 {
            return "\(Int(radiusMiles.rounded())) MI"
        } else if radiusMiles >= 0.1 {
            return String(format: "%.1f MI", radiusMiles)
        } else {
            let feet = radiusMiles * 5280
            let rounded = (feet / 50).rounded() * 50
            return "\(Int(rounded)) FT"
        }
    }
}
