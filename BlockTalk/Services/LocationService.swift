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
    /// The horizontal accuracy (meters) of the fix that produced `currentNeighborhood`.
    private var resolvedAccuracy: CLLocationAccuracy = .greatestFiniteMagnitude
    /// The location that produced the current resolved neighborhood.
    private var resolvedLocation: CLLocation?

    var permissionState: PermissionState = .unknown
    var currentLocation: CLLocationCoordinate2D?
    var currentNeighborhood: Neighborhood?

    var canPost: Bool { permissionState == .granted }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
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

    private func resolveNeighborhood(for location: CLLocation) {
        let accuracy = location.horizontalAccuracy
        guard accuracy >= 0 else { return } // negative = invalid

        let firstTime = currentNeighborhood == nil
        // Re-resolve if this fix is meaningfully more accurate (2× better),
        // OR the user has moved 200+ meters (crossed into another neighborhood).
        let dominated = !firstTime && accuracy < resolvedAccuracy * 0.5
        let moved = resolvedLocation.map { location.distance(from: $0) > 200 } ?? false

        guard firstTime || dominated || moved else { return }

        let coordinate = location.coordinate
        resolvedAccuracy = accuracy
        resolvedLocation = location

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
            let previousState = permissionState
            updatePermissionState()
            if permissionState == .granted {
                manager.startUpdatingLocation()
            }
            // Fire analytics when permission transitions from undetermined
            if previousState == .undetermined && (permissionState == .granted || permissionState == .denied) {
                Analytics.locationPermissionResult(granted: permissionState == .granted)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location.coordinate
            resolveNeighborhood(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
