import XCTest
@testable import BlockTalk

final class AppStateTests: XCTestCase {

    // MARK: - canPostInViewing

    func testCanPostInViewingNilNeighborhoods() {
        let state = AppState()
        state.physicalNeighborhood = nil
        state.viewingNeighborhood = nil
        XCTAssertFalse(state.canPostInViewing)
    }

    func testCanPostInViewingMismatch() {
        let state = AppState()
        state.physicalNeighborhood = TestFixtures.makeNeighborhood(name: "Chelsea")
        state.viewingNeighborhood = TestFixtures.makeNeighborhood(name: "SoHo")
        XCTAssertFalse(state.canPostInViewing)
    }

    func testCanPostInViewingCaseInsensitiveMatch() {
        let state = AppState()
        state.physicalNeighborhood = TestFixtures.makeNeighborhood(name: "chelsea")
        state.viewingNeighborhood = TestFixtures.makeNeighborhood(name: "Chelsea")
        XCTAssertTrue(state.canPostInViewing)
    }

    // MARK: - isAuthenticated

    func testIsAuthenticatedNilSession() {
        let state = AppState()
        state.session = nil
        XCTAssertFalse(state.isAuthenticated)
    }

    // MARK: - signOut

    func testSignOutResetsState() {
        let state = AppState()
        state.currentUser = BlockTalkUser(
            id: UUID(), username: "test", userNumber: 1,
            homeNeighborhoodId: UUID()
        )
        state.viewingNeighborhood = TestFixtures.makeNeighborhood()
        state.physicalNeighborhood = TestFixtures.makeNeighborhood()
        state.hasResolvedInitialNeighborhood = true
        state.selectedTab = 2

        state.signOut()

        XCTAssertNil(state.currentUser)
        XCTAssertNil(state.session)
        XCTAssertNil(state.viewingNeighborhood)
        XCTAssertNil(state.physicalNeighborhood)
        XCTAssertFalse(state.hasResolvedInitialNeighborhood)
        XCTAssertEqual(state.selectedTab, 0)
        XCTAssertEqual(state.stage, .splash)
    }
}
