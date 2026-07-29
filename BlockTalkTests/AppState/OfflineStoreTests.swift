import XCTest
@testable import BlockTalk

final class OfflineStoreTests: XCTestCase {

    func testEnqueueAddsToPending() {
        let store = OfflineStore()
        let post = TestFixtures.makePost()

        store.enqueue(post)

        XCTAssertEqual(store.pending.count, 1)
        XCTAssertEqual(store.pending[0].post.id, post.id)
    }

    func testExpireStaleFreshPostsUnchanged() {
        let store = OfflineStore()
        let post = TestFixtures.makePost()

        store.enqueue(post) // just enqueued, so still fresh
        store.expireStale()

        XCTAssertEqual(store.pending.count, 1)
        XCTAssertTrue(store.discarded.isEmpty)
    }

    func testForceExpireMovesAllToDiscarded() {
        let store = OfflineStore()
        store.enqueue(TestFixtures.makePost())
        store.enqueue(TestFixtures.makePost())

        store.forceExpire()

        XCTAssertTrue(store.pending.isEmpty)
        XCTAssertEqual(store.discarded.count, 2)
    }

    func testDismissDiscardedRemovesSpecificItem() {
        let store = OfflineStore()
        store.enqueue(TestFixtures.makePost())
        store.enqueue(TestFixtures.makePost())
        store.forceExpire()

        let idToRemove = store.discarded[0].id
        store.dismissDiscarded(idToRemove)

        XCTAssertEqual(store.discarded.count, 1)
        XCTAssertFalse(store.discarded.contains { $0.id == idToRemove })
    }

    func testResetClearsEverything() {
        let store = OfflineStore()
        store.isOffline = true
        store.enqueue(TestFixtures.makePost())
        store.forceExpire()

        store.reset()

        XCTAssertFalse(store.isOffline)
        XCTAssertTrue(store.pending.isEmpty)
        XCTAssertTrue(store.discarded.isEmpty)
        XCTAssertTrue(store.flushed.isEmpty)
    }

    func testToggleOfflineFlushes() {
        let store = OfflineStore()
        store.isOffline = true
        let post = TestFixtures.makePost()
        store.enqueue(post)

        store.toggleOffline() // goes back online

        XCTAssertFalse(store.isOffline)
        XCTAssertTrue(store.pending.isEmpty)
        XCTAssertEqual(store.flushed.count, 1)
        XCTAssertEqual(store.flushed[0].id, post.id)
    }
}
