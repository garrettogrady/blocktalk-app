import CoreLocation
import Foundation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum PermissionState {
        case unknown
        case undetermined
        case granted
        case denied
    }

    private let manager = CLLocationManager()
    private let neighborhoodService = NeighborhoodService()
    private var hasResolvedNeighborhood = false

    var permissionState: PermissionState = .unknown
    var currentLocation: CLLocationCoordinate2D?
    var currentNeighborhood: Neighborhood?

    var canPost: Bool { permissionState == .granted }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        updatePermissionState()
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func checkPermission() {
        updatePermissionState()
    }

    private func updatePermissionState() {
        switch manager.authorizationStatus {
        case .notDetermined:
            permissionState = .undetermined
        case .authorizedWhenInUse, .authorizedAlways:
            permissionState = .granted
        case .denied, .restricted:
            permissionState = .denied
        @unknown default:
            permissionState = .unknown
        }
    }

    /// Whether neighborhood resolution has been attempted (success or failure)
    var neighborhoodResolved = false

    private func resolveNeighborhood(for coordinate: CLLocationCoordinate2D) {
        // Only resolve once
        guard !hasResolvedNeighborhood else { return }
        hasResolvedNeighborhood = true

        Task { @MainActor in
            do {
                let neighborhood = try await neighborhoodService.findNeighborhood(at: coordinate)
                self.currentNeighborhood = neighborhood
            } catch {
                print("Failed to resolve neighborhood: \(error)")
            }
            self.neighborhoodResolved = true
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updatePermissionState()
            if permissionState == .granted {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location.coordinate
            resolveNeighborhood(for: location.coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
