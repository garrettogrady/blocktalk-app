import XCTest
@testable import BlockTalk

final class ModerationStoreTests: XCTestCase {

    func testReportMarksAsReported() {
        let store = ModerationStore()
        let postId = UUID()

        store.report(postId: postId, reasonShort: "spam")

        XCTAssertTrue(store.isReported(postId))
    }

    func testReportedPostIsHidden() {
        let store = ModerationStore()
        let postId = UUID()

        store.report(postId: postId, reasonShort: "hate")

        XCTAssertTrue(store.isHidden(postId))
    }

    func testToggleShowAnywayReveals() {
        let store = ModerationStore()
        let postId = UUID()

        store.report(postId: postId, reasonShort: "hate")
        store.toggleShowAnyway(postId)

        XCTAssertTrue(store.isReported(postId))
        XCTAssertFalse(store.isHidden(postId))
    }

    func testToggleShowAnywayReHides() {
        let store = ModerationStore()
        let postId = UUID()

        store.report(postId: postId, reasonShort: "hate")
        store.toggleShowAnyway(postId) // reveal
        store.toggleShowAnyway(postId) // re-hide

        XCTAssertTrue(store.isHidden(postId))
    }

    func testMarkAppealed() {
        let store = ModerationStore()
        let postId = UUID()

        XCTAssertFalse(store.hasAppealed(postId))
        store.markAppealed(postId)
        XCTAssertTrue(store.hasAppealed(postId))
    }

    func testMultipleIndependentPosts() {
        let store = ModerationStore()
        let post1 = UUID()
        let post2 = UUID()

        store.report(postId: post1, reasonShort: "spam")

        XCTAssertTrue(store.isReported(post1))
        XCTAssertFalse(store.isReported(post2))
        XCTAssertTrue(store.isHidden(post1))
        XCTAssertFalse(store.isHidden(post2))
    }

    func testReasonShort() {
        let store = ModerationStore()
        let postId = UUID()

        store.report(postId: postId, reasonShort: "hate speech")
        XCTAssertEqual(store.reasonShort(postId), "hate speech")
    }

    func testUnreportedPostNotHidden() {
        let store = ModerationStore()
        XCTAssertFalse(store.isHidden(UUID()))
    }
}
