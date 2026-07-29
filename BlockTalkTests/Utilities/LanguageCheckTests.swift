import XCTest
@testable import BlockTalk

final class LanguageCheckTests: XCTestCase {

    // MARK: - Clean text passes

    func testCleanTextPasses() {
        XCTAssertFalse(LanguageCheck.containsHateSpeech("Hello neighbors, great day!"))
    }

    func testEmptyStringPasses() {
        XCTAssertFalse(LanguageCheck.containsHateSpeech(""))
    }

    // MARK: - Category detection

    func testAntiBlackSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("you are a nigger"))
    }

    func testAntiBlackSlurCoon() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("you coon"))
    }

    func testAntiJewishSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("dirty kike"))
    }

    func testAntiLatinoSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("go back wetback"))
    }

    func testAntiAsianSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("stupid chink"))
    }

    func testAntiArabSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("dumb raghead"))
    }

    func testAntiLGBTQSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("shut up faggot"))
    }

    func testAntiTransSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("look at the tranny"))
    }

    func testAbleistSlurDetected() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("total mongoloid"))
    }

    // MARK: - Leetspeak evasion

    func testLeetspeakKike() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("k1ke"))
    }

    func testLeetspeakNigger() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("n!gger"))
    }

    func testLeetspeakFag() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("f@g"))
    }

    func testLeetspeakChink() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("ch1nk"))
    }

    // MARK: - Separator evasion

    func testDotSeparatorEvasion() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("k.i.k.e"))
    }

    func testSpaceSeparatorEvasion() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("k i k e"))
    }

    // MARK: - Allowlist (Scunthorpe problem)

    func testAllowlistRaccoon() {
        XCTAssertFalse(LanguageCheck.containsHateSpeech("saw a raccoon last night"))
    }

    func testAllowlistSpice() {
        XCTAssertFalse(LanguageCheck.containsHateSpeech("great spice shop"))
    }

    func testAllowlistDespicable() {
        XCTAssertFalse(LanguageCheck.containsHateSpeech("that's despicable behavior"))
    }

    func testAllowlistCocoon() {
        XCTAssertFalse(LanguageCheck.containsHateSpeech("butterfly cocoon"))
    }

    func testAllowlistGobbledygook() {
        XCTAssertFalse(LanguageCheck.containsHateSpeech("total gobbledygook"))
    }

    // MARK: - Multi-word slurs

    func testMultiWordPorchMonkey() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("you porch monkey"))
    }

    func testMultiWordJungleBunny() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("jungle bunny"))
    }

    func testMultiWordCamelJockey() {
        XCTAssertTrue(LanguageCheck.containsHateSpeech("camel jockey over there"))
    }
}
