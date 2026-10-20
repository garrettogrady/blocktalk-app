import XCTest
import Supabase
@testable import BlockTalk

final class RateLimitTests: XCTestCase {

    func testExtractsSentenceFromPostgrestStyleMessage() {
        let raw = #"PostgrestError(detail: nil, hint: nil, code: Optional("P0001"), message: "rate_limited: Slow down. You can post again in about a minute.")"#
        XCTAssertEqual(RateLimit.message(in: raw), "Slow down. You can post again in about a minute.")
    }

    func testExtractsBareMessage() {
        XCTAssertEqual(RateLimit.message(in: "rate_limited: You've hit today's reply limit. Try again tomorrow."),
                       "You've hit today's reply limit. Try again tomorrow.")
    }

    func testIgnoresOtherErrors() {
        XCTAssertNil(RateLimit.message(in: "column users_1.aura does not exist"))
        XCTAssertNil(RateLimit.message(in: ""))
    }

    func testEmptySentenceIsNil() {
        XCTAssertNil(RateLimit.message(in: "rate_limited: "))
    }
}

final class EditHistoryStampTests: XCTestCase {
    private let cal = Calendar.current

    func testToday() {
        let now = Date()
        XCTAssertTrue(EditHistorySheet.stamp(now, now: now).hasPrefix("TODAY · "))
    }

    func testYesterday() {
        let now = Date()
        let y = cal.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(EditHistorySheet.stamp(y, now: now).hasPrefix("YESTERDAY · "))
    }

    func testOlderShowsMonthAndDay() {
        let now = Date()
        let d = cal.date(byAdding: .day, value: -3, to: now)!
        let s = EditHistorySheet.stamp(d, now: now)
        XCTAssertFalse(s.hasPrefix("TODAY"))
        XCTAssertFalse(s.hasPrefix("YESTERDAY"))
        XCTAssertTrue(s.contains(" · "))
    }
}

final class ServerMessageTests: XCTestCase {
    private func pg(code: String?, message: String) -> PostgrestError {
        PostgrestError(detail: nil, hint: nil, code: code, message: message)
    }

    func testPassesThroughOurOwnRefusals() {
        let e = pg(code: "P0001", message: "That spot is too far from where you are. Pins stay within a block of you.")
        XCTAssertEqual(ServerMessage.text(for: e), "That spot is too far from where you are. Pins stay within a block of you.")
    }

    func testIgnoresRateLimitSoRateLimitHandlesIt() {
        let e = pg(code: "P0001", message: "rate_limited: Slow down. You can post again in about a minute.")
        XCTAssertNil(ServerMessage.text(for: e))
        XCTAssertEqual(RateLimit.message(for: e), "Slow down. You can post again in about a minute.")
    }

    func testIgnoresOtherCodes() {
        // The bug that bit create_pin: an auth refusal is not user copy.
        XCTAssertNil(ServerMessage.text(for: pg(code: "42501", message: "Not authorized")))
        XCTAssertNil(ServerMessage.text(for: pg(code: "42703", message: "column users_1.aura does not exist")))
        XCTAssertNil(ServerMessage.text(for: pg(code: nil, message: "anything")))
    }

    func testNonPostgrestErrorsAreNil() {
        XCTAssertNil(ServerMessage.text(for: URLError(.notConnectedToInternet)))
        XCTAssertNil(RateLimit.message(for: URLError(.notConnectedToInternet)))
    }
}
