import XCTest
@testable import BlockTalk

final class DailyPromptTests: XCTestCase {

    // MARK: - isActive

    func testIsActiveBeforeWindow() {
        let prompt = TestFixtures.makeDailyPrompt(
            activeFrom: Date().addingTimeInterval(3600),
            activeUntil: Date().addingTimeInterval(7200)
        )
        XCTAssertFalse(prompt.isActive)
    }

    func testIsActiveDuringWindow() {
        let prompt = TestFixtures.makeDailyPrompt(
            activeFrom: Date().addingTimeInterval(-3600),
            activeUntil: Date().addingTimeInterval(3600)
        )
        XCTAssertTrue(prompt.isActive)
    }

    func testIsActiveAfterWindow() {
        let prompt = TestFixtures.makeDailyPrompt(
            activeFrom: Date().addingTimeInterval(-7200),
            activeUntil: Date().addingTimeInterval(-3600)
        )
        XCTAssertFalse(prompt.isActive)
    }

    // MARK: - timeRemaining

    func testTimeRemainingExpired() {
        let prompt = TestFixtures.makeDailyPrompt(
            activeUntil: Date().addingTimeInterval(-60)
        )
        XCTAssertEqual(prompt.timeRemaining, "expired")
    }

    func testTimeRemainingDaysAndHours() {
        // 2 days + 3 hours from now
        let prompt = TestFixtures.makeDailyPrompt(
            activeUntil: Date().addingTimeInterval(2 * 86400 + 3 * 3600)
        )
        XCTAssertTrue(prompt.timeRemaining.contains("d"))
        XCTAssertTrue(prompt.timeRemaining.contains("h"))
        XCTAssertTrue(prompt.timeRemaining.hasSuffix("LEFT"))
    }

    func testTimeRemainingHoursAndMinutes() {
        // 2 hours 30 minutes from now
        let prompt = TestFixtures.makeDailyPrompt(
            activeUntil: Date().addingTimeInterval(2 * 3600 + 30 * 60)
        )
        let remaining = prompt.timeRemaining
        XCTAssertTrue(remaining.contains("h"))
        XCTAssertTrue(remaining.contains("m"))
        XCTAssertTrue(remaining.hasSuffix("LEFT"))
        XCTAssertFalse(remaining.contains("d"))
    }

    func testTimeRemainingMinutesOnly() {
        // 45 minutes from now
        let prompt = TestFixtures.makeDailyPrompt(
            activeUntil: Date().addingTimeInterval(45 * 60)
        )
        let remaining = prompt.timeRemaining
        XCTAssertTrue(remaining.contains("m"))
        XCTAssertTrue(remaining.hasSuffix("LEFT"))
        XCTAssertFalse(remaining.contains("h"))
        XCTAssertFalse(remaining.contains("d"))
    }
}
