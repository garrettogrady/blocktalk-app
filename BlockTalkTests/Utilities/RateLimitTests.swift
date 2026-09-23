import XCTest
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
