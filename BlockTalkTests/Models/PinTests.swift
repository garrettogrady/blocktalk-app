import XCTest
@testable import BlockTalk

final class PinTests: XCTestCase {

    func testSymbolGym() {
        XCTAssertEqual(Pin.symbol(forCategory: "gym"), "dumbbell.fill")
    }

    func testSymbolRestaurant() {
        XCTAssertEqual(Pin.symbol(forCategory: "restaurant"), "fork.knife")
    }

    func testSymbolCafe() {
        XCTAssertEqual(Pin.symbol(forCategory: "cafe"), "cup.and.saucer.fill")
    }

    func testSymbolUnknownDefault() {
        XCTAssertEqual(Pin.symbol(forCategory: "unknown"), "mappin.circle.fill")
    }

    func testSymbolCaseInsensitive() {
        XCTAssertEqual(Pin.symbol(forCategory: "GYM"), "dumbbell.fill")
        XCTAssertEqual(Pin.symbol(forCategory: "Restaurant"), "fork.knife")
        XCTAssertEqual(Pin.symbol(forCategory: "BAKERY"), "birthday.cake.fill")
    }
}
