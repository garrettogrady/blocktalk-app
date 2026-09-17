import XCTest
@testable import BlockTalk

final class ContentEditStoreTests: XCTestCase {

    // MARK: - Posts

    func testUntouchedPostPassesThrough() {
        let store = ContentEditStore()
        let post = TestFixtures.makePost(text: "hello")
        XCTAssertEqual(store.apply(post).text, "hello")
        XCTAssertEqual(store.apply(post).status, .live)
    }

    func testEditPatchesTextAndHistory() {
        let store = ContentEditStore()
        let post = TestFixtures.makePost(text: "hello")
        let when = Date()

        store.recordEdit(postId: post.id, .init(text: "hello there", originalText: "hello", editedAt: when, editCount: 1))
        let shown = store.apply(post)

        XCTAssertEqual(shown.text, "hello there")
        XCTAssertEqual(shown.originalText, "hello")
        XCTAssertEqual(shown.editedAt, when)
        XCTAssertEqual(shown.editCount, 1)
    }

    func testSilentEditLeavesNoTag() {
        let store = ContentEditStore()
        let post = TestFixtures.makePost(text: "hello")

        store.recordEdit(postId: post.id, .init(text: "helo", originalText: nil, editedAt: nil, editCount: 0))

        XCTAssertEqual(store.apply(post).text, "helo")
        XCTAssertNil(store.apply(post).editedAt)
    }

    func testTombstoneBlanksBodyAndMarksDeleted() {
        let store = ContentEditStore()
        let post = TestFixtures.makePost(text: "hello", replyCount: 3, imageUrl: "https://x/y.jpg")

        store.recordTombstone(postId: post.id)
        let shown = store.apply(post)

        XCTAssertEqual(shown.status, .deleted)
        XCTAssertEqual(shown.text, "[deleted]")
        XCTAssertNil(shown.imageUrl)
        XCTAssertEqual(shown.replyCount, 3, "surviving replies keep their count")
    }

    func testHardDeleteIsTracked() {
        let store = ContentEditStore()
        let id = UUID()
        XCTAssertFalse(store.isHardDeleted(postId: id))
        store.recordHardDelete(postId: id)
        XCTAssertTrue(store.isHardDeleted(postId: id))
    }

    // MARK: - Replies

    func testReplyTombstoneKeepsChildren() {
        let store = ContentEditStore()
        let child = TestFixtures.makeReply(text: "child", depth: 1)
        let parent = TestFixtures.makeReply(text: "parent", children: [child])

        store.recordTombstone(replyId: parent.id)
        let shown = store.apply(parent)

        XCTAssertTrue(shown.isDeleted)
        XCTAssertEqual(shown.text, "[deleted]")
        XCTAssertEqual(shown.children?.count, 1)
    }

    func testDescendantCountIsRecursive() {
        let leaf = TestFixtures.makeReply(text: "leaf", depth: 2)
        let mid = TestFixtures.makeReply(text: "mid", depth: 1, children: [leaf])
        let root = TestFixtures.makeReply(text: "root", children: [mid, TestFixtures.makeReply(text: "sibling", depth: 1)])

        XCTAssertEqual(root.descendantCount, 3)
        XCTAssertEqual(leaf.descendantCount, 0)
    }

    func testResetClearsEverything() {
        let store = ContentEditStore()
        let id = UUID()
        store.recordHardDelete(postId: id)
        store.recordTombstone(replyId: id)
        store.reset()
        XCTAssertFalse(store.isHardDeleted(postId: id))
        XCTAssertFalse(store.apply(TestFixtures.makeReply(id: id)).isDeleted)
    }
}
