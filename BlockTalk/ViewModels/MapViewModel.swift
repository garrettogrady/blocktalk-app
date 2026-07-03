import Foundation
import MapKit

@Observable
final class MapViewModel {
    var pins: [Pin] = []
    var neighborhoods: [Neighborhood] = []
    var isLoading = false
    var error: String?
    var isDropMode = false
    var dropCenter: CLLocationCoordinate2D?
    var radiusMiles: Double = 0.5

    // NYC center
    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7193, longitude: -73.9911),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.024)
    )

    private let pinService = PinService()
    private let neighborhoodService = NeighborhoodService()

    func loadPins(neighborhoodId: UUID) async {
        do {
            pins = try await pinService.fetchPinsForNeighborhood(neighborhoodId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAllPins() async {
        do {
            pins = try await pinService.fetchAllPins()
        } catch {
            self.error = error.localizedDescription
            print("Failed to load pins: \(error)")
        }
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
