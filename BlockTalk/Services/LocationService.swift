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

        let coordinate = location.coordinate

        // Cheap local point-in-polygon on every fix — which neighborhood the
        // coordinate is actually inside right now.
        let localMatch = NeighborhoodPolygonLoader.load().first(where: { $0.contains(coordinate) })

        let firstTime = currentNeighborhood == nil
        // Re-resolve when we don't have one yet, when the coordinate is now inside a
        // DIFFERENT neighborhood than we last resolved (you crossed a boundary — even
        // a few meters between adjacent NYC neighborhoods, e.g. LES → Nolita), or when
        // a materially better fix arrives. Over water / in a gap (no polygon match),
        // keep the current neighborhood rather than clearing it.
        let crossedBoundary = localMatch != nil && localMatch?.name != currentNeighborhood?.name
        let dominated = !firstTime && accuracy < resolvedAccuracy * 0.5

        guard firstTime || crossedBoundary || dominated else { return }

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
