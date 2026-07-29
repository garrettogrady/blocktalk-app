import XCTest
import MapKit
@testable import BlockTalk

final class MapViewModelTests: XCTestCase {

    // MARK: - formatRadius

    func testFormatRadiusLargeValueMiles() {
        let vm = MapViewModel()
        vm.radiusMiles = 12.3
        XCTAssertEqual(vm.formatRadius(), "12 MI")
    }

    func testFormatRadiusMediumValueMiles() {
        let vm = MapViewModel()
        vm.radiusMiles = 0.5
        XCTAssertEqual(vm.formatRadius(), "0.5 MI")
    }

    func testFormatRadiusSmallValueFeet() {
        let vm = MapViewModel()
        vm.radiusMiles = 0.05 // 264 feet → rounds to 250
        let result = vm.formatRadius()
        XCTAssertTrue(result.hasSuffix("FT"))
    }

    func testFormatRadiusExactly10Miles() {
        let vm = MapViewModel()
        vm.radiusMiles = 10.0
        XCTAssertEqual(vm.formatRadius(), "10 MI")
    }

    // MARK: - enterDropMode / cancelDrop

    func testEnterDropMode() {
        let vm = MapViewModel()
        XCTAssertFalse(vm.isDropMode)
        XCTAssertNil(vm.dropCenter)

        vm.enterDropMode()

        XCTAssertTrue(vm.isDropMode)
        XCTAssertNotNil(vm.dropCenter)
    }

    func testCancelDrop() {
        let vm = MapViewModel()
        vm.enterDropMode()
        vm.cancelDrop()

        XCTAssertFalse(vm.isDropMode)
        XCTAssertNil(vm.dropCenter)
    }
}
