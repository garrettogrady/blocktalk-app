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
