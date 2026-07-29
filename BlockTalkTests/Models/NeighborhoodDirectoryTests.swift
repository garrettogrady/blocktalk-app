import XCTest
@testable import BlockTalk

final class NeighborhoodDirectoryTests: XCTestCase {

    func testNameForShortCodeLES() {
        XCTAssertEqual(NeighborhoodDirectory.name(forShortCode: "LES"), "Lower East Side")
    }

    func testShortCodeForNameLowerEastSide() {
        XCTAssertEqual(NeighborhoodDirectory.shortCode(forName: "Lower East Side"), "LES")
    }

    func testNameForUnknownShortCodeReturnsNil() {
        XCTAssertNil(NeighborhoodDirectory.name(forShortCode: "ZZZZ"))
    }

    func testShortCodeForUnknownNameReturnsNil() {
        XCTAssertNil(NeighborhoodDirectory.shortCode(forName: "Narnia"))
    }

    func testGroupedReturnsFiveBoroughs() {
        let grouped = NeighborhoodDirectory.grouped()
        XCTAssertEqual(grouped.count, 5)
        let boroughNames = grouped.map(\.borough)
        XCTAssertTrue(boroughNames.contains("Manhattan"))
        XCTAssertTrue(boroughNames.contains("Brooklyn"))
        XCTAssertTrue(boroughNames.contains("Queens"))
        XCTAssertTrue(boroughNames.contains("Bronx"))
        XCTAssertTrue(boroughNames.contains("Staten Island"))
        // Each borough should have entries
        for group in grouped {
            XCTAssertFalse(group.entries.isEmpty, "\(group.borough) should have entries")
        }
    }
}
