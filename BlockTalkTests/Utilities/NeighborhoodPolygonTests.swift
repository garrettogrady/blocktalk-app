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

final class NeighborhoodPolygonGraceTests: XCTestCase {
    // A 1 km square-ish box around a point in the LES.
    private let box = NeighborhoodPolygon(name: "Box", rings: [[
        CLLocationCoordinate2D(latitude: 40.7150, longitude: -73.9900),
        CLLocationCoordinate2D(latitude: 40.7150, longitude: -73.9800),
        CLLocationCoordinate2D(latitude: 40.7240, longitude: -73.9800),
        CLLocationCoordinate2D(latitude: 40.7240, longitude: -73.9900),
    ]])

    func testInsideHasZeroDistanceSemantics() {
        let inside = CLLocationCoordinate2D(latitude: 40.7195, longitude: -73.9850)
        XCTAssertTrue(box.contains(inside))
        XCTAssertTrue(box.containsWithGrace(inside))
    }

    func testJustOutsideIsWithinGrace() {
        // ~50 m south of the southern edge (0.00045 deg lat).
        let p = CLLocationCoordinate2D(latitude: 40.7150 - 0.00045, longitude: -73.9850)
        XCTAssertFalse(box.contains(p))
        XCTAssertEqual(box.distanceToEdge(p), 50, accuracy: 5)
        XCTAssertTrue(box.containsWithGrace(p))
    }

    func testFarOutsideIsNotWithinGrace() {
        // ~400 m south.
        let p = CLLocationCoordinate2D(latitude: 40.7150 - 0.0036, longitude: -73.9850)
        XCTAssertFalse(box.containsWithGrace(p))
        XCTAssertEqual(box.distanceToEdge(p), 400, accuracy: 10)
    }

    func testGraceLimitIsAboutABlock() {
        XCTAssertEqual(NeighborhoodPolygon.graceMeters, 150)
    }
}

final class NeighborhoodPolygonLookupTests: XCTestCase {
    func testBoundingRegionCoversPolygonWithPadding() {
        let box = NeighborhoodPolygon(name: "Box", rings: [[
            CLLocationCoordinate2D(latitude: 40.7150, longitude: -73.9900),
            CLLocationCoordinate2D(latitude: 40.7150, longitude: -73.9800),
            CLLocationCoordinate2D(latitude: 40.7240, longitude: -73.9800),
            CLLocationCoordinate2D(latitude: 40.7240, longitude: -73.9900),
        ]])
        let r = box.boundingRegion(paddingMeters: 150)
        XCTAssertEqual(r.center.latitude, 40.7195, accuracy: 1e-6)
        XCTAssertEqual(r.center.longitude, -73.9850, accuracy: 1e-6)
        // 0.009 deg of polygon plus 150 m (~0.00135 deg) on each side
        XCTAssertEqual(r.span.latitudeDelta, 0.009 + 2 * 150.0 / 111_000, accuracy: 1e-5)
        XCTAssertGreaterThan(r.span.longitudeDelta, 0.010)
    }

    func testNamedResolvesExactAndAliasedNames() {
        let all = NeighborhoodPolygonLoader.load()
        XCTAssertEqual(NeighborhoodPolygon.named("Lower East Side", in: all)?.name, "Lower East Side")
        XCTAssertEqual(NeighborhoodPolygon.named("lower east side", in: all)?.name, "Lower East Side")
        // Supabase says "Flatiron"; the bundle says "Flatiron District".
        XCTAssertEqual(NeighborhoodPolygon.named("Flatiron", in: all)?.name, "Flatiron District")
        XCTAssertNil(NeighborhoodPolygon.named("Narnia", in: all))
    }

    func testDimesSquareIsLowerEastSideNow() {
        let all = NeighborhoodPolygonLoader.load()
        let les = NeighborhoodPolygon.named("Lower East Side", in: all)!
        let chinatown = NeighborhoodPolygon.named("Chinatown", in: all)!
        let dimes = CLLocationCoordinate2D(latitude: 40.7146, longitude: -73.9910)
        XCTAssertTrue(les.contains(dimes))
        XCTAssertFalse(chinatown.contains(dimes))
        // West side of Bowery stays Chinatown.
        let bowery = CLLocationCoordinate2D(latitude: 40.7185, longitude: -73.9960)
        XCTAssertTrue(chinatown.contains(bowery))
        XCTAssertFalse(les.contains(bowery))
    }
}
