import XCTest
@testable import BlockTalk

final class ProfileViewModelTests: XCTestCase {

    // MARK: - usernameState

    func testEmptyUsernameState() {
        let vm = ProfileViewModel()
        vm.username = ""
        XCTAssertEqual(vm.usernameState, .empty)
    }

    func testWhitespaceOnlyUsernameState() {
        let vm = ProfileViewModel()
        vm.username = "   "
        XCTAssertEqual(vm.usernameState, .empty)
    }

    func testDefaultUsernameState() {
        let vm = ProfileViewModel()
        vm.username = "BlockTalker"
        XCTAssertEqual(vm.usernameState, .default)
    }

    func testDefaultUsernameStateCaseInsensitive() {
        let vm = ProfileViewModel()
        vm.username = "blocktalker"
        XCTAssertEqual(vm.usernameState, .default)
    }

    func testTooShortUsernameState() {
        let vm = ProfileViewModel()
        vm.username = "ab"
        XCTAssertEqual(vm.usernameState, .invalid)
    }

    func testTooLongUsernameState() {
        let vm = ProfileViewModel()
        vm.username = String(repeating: "a", count: 21)
        XCTAssertEqual(vm.usernameState, .invalid)
    }

    func testInvalidCharsUsernameState() {
        let vm = ProfileViewModel()
        vm.username = "user name!" // space and ! are invalid
        XCTAssertEqual(vm.usernameState, .invalid)
    }

    func testBlockedUsernameStateMod() {
        let vm = ProfileViewModel()
        vm.username = "mod"
        XCTAssertEqual(vm.usernameState, .blocked)
    }

    func testBlockedUsernameStateStaff() {
        let vm = ProfileViewModel()
        vm.username = "staff"
        XCTAssertEqual(vm.usernameState, .blocked)
    }

    func testBlockedUsernameStateModerator() {
        let vm = ProfileViewModel()
        vm.username = "moderator"
        XCTAssertEqual(vm.usernameState, .blocked)
    }

    func testHateSpeechUsernameState() {
        let vm = ProfileViewModel()
        vm.username = "kikekiller"
        XCTAssertEqual(vm.usernameState, .hate)
    }

    func testTakenUsernameState() {
        let vm = ProfileViewModel()
        vm.username = "validuser"
        vm.isUsernameTaken = true
        XCTAssertEqual(vm.usernameState, .taken)
    }

    func testValidUsernameState() {
        let vm = ProfileViewModel()
        vm.username = "cool_user_42"
        XCTAssertEqual(vm.usernameState, .valid)
    }

    // MARK: - canContinue

    func testCanContinueRequiresValidUsernameAndNeighborhood() {
        let vm = ProfileViewModel()
        vm.username = "validuser"
        vm.selectedNeighborhood = nil
        XCTAssertFalse(vm.canContinue)

        vm.selectedNeighborhood = TestFixtures.makeNeighborhood()
        XCTAssertTrue(vm.canContinue)
    }

    func testCanContinueWithDefaultUsername() {
        let vm = ProfileViewModel()
        vm.username = "BlockTalker"
        vm.selectedNeighborhood = TestFixtures.makeNeighborhood()
        XCTAssertTrue(vm.canContinue)
    }
}
