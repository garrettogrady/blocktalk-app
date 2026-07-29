import XCTest
@testable import BlockTalk

final class ComposeViewModelTests: XCTestCase {

    func testIsOverLimitAtLimit() {
        let vm = ComposeViewModel()
        vm.text = String(repeating: "a", count: 1500)
        XCTAssertFalse(vm.isOverLimit)
    }

    func testIsOverLimitAboveLimit() {
        let vm = ComposeViewModel()
        vm.text = String(repeating: "a", count: 1501)
        XCTAssertTrue(vm.isOverLimit)
    }

    func testShowCounterBelowThreshold() {
        let vm = ComposeViewModel()
        vm.text = String(repeating: "a", count: 1049)
        XCTAssertFalse(vm.showCounter)
    }

    func testShowCounterAtThreshold() {
        let vm = ComposeViewModel()
        vm.text = String(repeating: "a", count: 1050)
        XCTAssertTrue(vm.showCounter)
    }

    func testCanSubmitEmptyText() {
        let vm = ComposeViewModel()
        vm.text = ""
        XCTAssertFalse(vm.canSubmit)
    }

    func testCanSubmitWhitespaceOnly() {
        let vm = ComposeViewModel()
        vm.text = "   \n  "
        XCTAssertFalse(vm.canSubmit)
    }

    func testCanSubmitOverLimit() {
        let vm = ComposeViewModel()
        vm.text = String(repeating: "a", count: 1501)
        XCTAssertFalse(vm.canSubmit)
    }

    func testCanSubmitHateSpeech() {
        let vm = ComposeViewModel()
        vm.text = "you are a nigger"
        XCTAssertFalse(vm.canSubmit)
    }

    func testCanSubmitIsSubmitting() {
        let vm = ComposeViewModel()
        vm.text = "Valid post"
        vm.isSubmitting = true
        XCTAssertFalse(vm.canSubmit)
    }

    func testCanSubmitValid() {
        let vm = ComposeViewModel()
        vm.text = "Hello neighbors!"
        XCTAssertTrue(vm.canSubmit)
    }

    func testResetClearsState() {
        let vm = ComposeViewModel()
        vm.text = "Some text"
        vm.error = "Something failed"
        vm.isDailyPrompt = true
        vm.isNYCWide = true
        vm.reset()
        XCTAssertEqual(vm.text, "")
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.isDailyPrompt)
        XCTAssertFalse(vm.isNYCWide)
        XCTAssertNil(vm.pinLocation)
        XCTAssertNil(vm.cornerName)
    }
}
