import XCTest
import CoreLocation
@testable import BlockTalk

final class NeighborhoodPolygonTests: XCTestCase {

    // MARK: - pointInRing

    func testPointInsideSquare() {
        let inside = CLLocationCoordinate2D(latitude: 5, longitude: 5)
        XCTAssertTrue(NeighborhoodPolygon.pointInRing(inside, TestFixtures.squareRing))
    }

    func testPointOutsideSquare() {
        let outside = CLLocationCoordinate2D(latitude: 15, longitude: 15)
        XCTAssertFalse(NeighborhoodPolygon.pointInRing(outside, TestFixtures.squareRing))
    }

    func testFewerThan3PointsReturnsFalse() {
        let twoPoints = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
        ]
        let point = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)
        XCTAssertFalse(NeighborhoodPolygon.pointInRing(point, twoPoints))
    }

    func testEmptyRingReturnsFalse() {
        let point = CLLocationCoordinate2D(latitude: 5, longitude: 5)
        XCTAssertFalse(NeighborhoodPolygon.pointInRing(point, []))
    }

    // MARK: - contains (multiple rings)

    func testContainsWithMultipleRings() {
        let secondRing: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 20, longitude: 20),
            CLLocationCoordinate2D(latitude: 20, longitude: 30),
            CLLocationCoordinate2D(latitude: 30, longitude: 30),
            CLLocationCoordinate2D(latitude: 30, longitude: 20),
            CLLocationCoordinate2D(latitude: 20, longitude: 20),
        ]
        let polygon = NeighborhoodPolygon(name: "Test", rings: [TestFixtures.squareRing, secondRing])

        // Inside first ring
        XCTAssertTrue(polygon.contains(CLLocationCoordinate2D(latitude: 5, longitude: 5)))
        // Inside second ring
        XCTAssertTrue(polygon.contains(CLLocationCoordinate2D(latitude: 25, longitude: 25)))
        // Outside both
        XCTAssertFalse(polygon.contains(CLLocationCoordinate2D(latitude: 15, longitude: 15)))
    }

    // MARK: - center

    func testCenterComputation() {
        let polygon = NeighborhoodPolygon(name: "Test", rings: [TestFixtures.squareRing])
        let center = polygon.center
        // Square 0-10: average of corners (0,0),(0,10),(10,10),(10,0),(0,0) = (4,4)
        XCTAssertEqual(center.latitude, 4.0, accuracy: 0.01)
        XCTAssertEqual(center.longitude, 4.0, accuracy: 0.01)
    }

    func testEmptyRingsDefaultToNYC() {
        let polygon = NeighborhoodPolygon(name: "Empty", rings: [])
        let center = polygon.center
        XCTAssertEqual(center.latitude, 40.7128, accuracy: 0.001)
        XCTAssertEqual(center.longitude, -74.0060, accuracy: 0.001)
    }

    func testEmptyRingInsideArrayDefaultsToNYC() {
        let polygon = NeighborhoodPolygon(name: "Empty Ring", rings: [[]])
        let center = polygon.center
        XCTAssertEqual(center.latitude, 40.7128, accuracy: 0.001)
        XCTAssertEqual(center.longitude, -74.0060, accuracy: 0.001)
    }

    // MARK: - Real-world coordinate

    func testKnownLESCoordinate() {
        // A known point inside Lower East Side
        let lesPoint = CLLocationCoordinate2D(latitude: 40.7185, longitude: -73.9868)
        let polygons = NeighborhoodPolygonLoader.load()
        let match = polygons.first { $0.contains(lesPoint) }
        // This test only works if the bundle JSON is available; skip otherwise
        if !polygons.isEmpty {
            XCTAssertNotNil(match, "Expected LES coordinate to resolve to a neighborhood")
        }
    }
}
