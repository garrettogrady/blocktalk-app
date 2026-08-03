import CoreLocation
import XCTest
@testable import BlockTalk

final class OfflineStoreTests: XCTestCase {

    private func makeStore() -> OfflineStore {
        let store = OfflineStore()
        // Stop the real NWPathMonitor so tests don't get spurious connectivity events
        store.stopMonitor()
        return store
    }

    func testEnqueueAddsToPending() {
        let store = makeStore()
        let queued = TestFixtures.makeQueuedPost()

        store.enqueue(queued)

        XCTAssertEqual(store.pending.count, 1)
        XCTAssertEqual(store.pending[0].post.id, queued.post.id)
        XCTAssertEqual(store.pending[0].text, "Hello neighbors!")
        XCTAssertEqual(store.pending[0].userId, TestFixtures.userId)
    }

    func testEnqueueCapturesPinMetadata() {
        let store = makeStore()
        let coord = CLLocationCoordinate2D(latitude: 40.72, longitude: -73.99)
        let queued = TestFixtures.makeQueuedPost(
            pinCoordinate: coord,
            pinCornerName: "Essex & Delancey",
            placeName: "Essex Market",
            placeCategory: "Market",
            placeSymbol: "cart.fill"
        )

        store.enqueue(queued)

        XCTAssertEqual(store.pending[0].pinCornerName, "Essex & Delancey")
        XCTAssertEqual(store.pending[0].placeName, "Essex Market")
        XCTAssertNotNil(store.pending[0].pinCoordinate)
    }

    func testExpireStaleFreshPostsUnchanged() {
        let store = makeStore()
        let queued = TestFixtures.makeQueuedPost()

        store.enqueue(queued) // just enqueued, so still fresh
        store.expireStale()

        XCTAssertEqual(store.pending.count, 1)
        XCTAssertTrue(store.discarded.isEmpty)
    }

    func testForceExpireMovesAllToDiscarded() {
        let store = makeStore()
        store.enqueue(TestFixtures.makeQueuedPost())
        store.enqueue(TestFixtures.makeQueuedPost())

        store.forceExpire()

        XCTAssertTrue(store.pending.isEmpty)
        XCTAssertEqual(store.discarded.count, 2)
    }

    func testDismissDiscardedRemovesSpecificItem() {
        let store = makeStore()
        store.enqueue(TestFixtures.makeQueuedPost())
        store.enqueue(TestFixtures.makeQueuedPost())
        store.forceExpire()

        let idToRemove = store.discarded[0].id
        store.dismissDiscarded(idToRemove)

        XCTAssertEqual(store.discarded.count, 1)
        XCTAssertFalse(store.discarded.contains { $0.id == idToRemove })
    }

    func testResetClearsEverything() {
        let store = makeStore()
        store.isOffline = true
        store.enqueue(TestFixtures.makeQueuedPost())
        store.forceExpire()

        store.reset()

        XCTAssertFalse(store.isOffline)
        XCTAssertTrue(store.pending.isEmpty)
        XCTAssertTrue(store.discarded.isEmpty)
        XCTAssertTrue(store.flushed.isEmpty)
    }

    #if DEBUG
    func testToggleOfflineTriggersFlush() {
        let store = makeStore()
        store.isOffline = true
        let queued = TestFixtures.makeQueuedPost()
        store.enqueue(queued)

        // toggleOffline triggers an async flush; without a real backend
        // the posts stay pending (flush will fail). Verify the toggle
        // itself updates the isOffline flag correctly.
        store.toggleOffline()

        XCTAssertFalse(store.isOffline)
    }
    #endif

    func testExpireStaleMovesOldPosts() {
        let store = makeStore()
        // Create a post queued well past the grace window
        let oldDate = Date().addingTimeInterval(-(OfflineStore.graceSeconds + 10))
        let queued = TestFixtures.makeQueuedPost(queuedAt: oldDate)
        store.enqueue(queued)

        store.expireStale()

        XCTAssertTrue(store.pending.isEmpty)
        XCTAssertEqual(store.discarded.count, 1)
    }

    func testFlushWithNoPendingIsNoop() async {
        let store = makeStore()

        await store.flush()

        XCTAssertTrue(store.flushed.isEmpty)
        XCTAssertTrue(store.pending.isEmpty)
    }
}
