import XCTest
@testable import BlockTalk

final class PostDetailViewModelTests: XCTestCase {

    // MARK: - insert at root

    func testInsertAtRoot() {
        let vm = PostDetailViewModel()
        var nodes: [Reply] = []
        let reply = TestFixtures.makeReply(depth: 5) // depth should be reset to 0

        vm.insert(reply, under: nil, into: &nodes)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].depth, 0)
        XCTAssertNil(nodes[0].parentReplyId)
    }

    // MARK: - insert under parent

    func testInsertUnderParent() {
        let vm = PostDetailViewModel()
        let parentId = UUID()
        let parent = TestFixtures.makeReply(id: parentId, depth: 0)
        var nodes: [Reply] = [parent]

        let child = TestFixtures.makeReply(text: "child reply")
        vm.insert(child, under: parentId, into: &nodes)

        XCTAssertEqual(nodes.count, 1) // child nested, not appended
        XCTAssertEqual(nodes[0].children?.count, 1)
        XCTAssertEqual(nodes[0].children?[0].depth, 1)
        XCTAssertEqual(nodes[0].children?[0].parentReplyId, parentId)
    }

    // MARK: - depth capped at maxDepth

    func testDepthCappedAtMaxDepth() {
        let vm = PostDetailViewModel()
        let parentId = UUID()
        let parent = TestFixtures.makeReply(id: parentId, depth: Reply.maxDepth)
        var nodes: [Reply] = [parent]

        let child = TestFixtures.makeReply(text: "deep reply")
        vm.insert(child, under: parentId, into: &nodes)

        let insertedDepth = nodes[0].children?[0].depth ?? -1
        XCTAssertEqual(insertedDepth, Reply.maxDepth, "Depth should not exceed maxDepth (\(Reply.maxDepth))")
    }

    // MARK: - non-existent parent falls back to root

    func testNonExistentParentFallsBackToRoot() {
        let vm = PostDetailViewModel()
        var nodes: [Reply] = [TestFixtures.makeReply()]

        let orphan = TestFixtures.makeReply(text: "orphan")
        vm.insert(orphan, under: UUID(), into: &nodes) // bogus parent ID

        XCTAssertEqual(nodes.count, 2, "Orphan should be appended at root")
        XCTAssertEqual(nodes[1].depth, 0)
        XCTAssertNil(nodes[1].parentReplyId)
    }

    // MARK: - graft

    func testGraftFindsNestedParent() {
        let vm = PostDetailViewModel()
        let grandparentId = UUID()
        let parentId = UUID()
        let grandparent = TestFixtures.makeReply(
            id: grandparentId,
            depth: 0,
            children: [TestFixtures.makeReply(id: parentId, depth: 1)]
        )
        var nodes: [Reply] = [grandparent]

        let child = TestFixtures.makeReply(text: "deep child")
        let found = vm.graft(child, under: parentId, into: &nodes)

        XCTAssertTrue(found)
        XCTAssertEqual(nodes[0].children?[0].children?.count, 1)
    }

    func testGraftReturnsFalseWhenParentNotFound() {
        let vm = PostDetailViewModel()
        var nodes: [Reply] = [TestFixtures.makeReply()]

        let found = vm.graft(TestFixtures.makeReply(), under: UUID(), into: &nodes)
        XCTAssertFalse(found)
    }

    // MARK: - replyHasHate

    func testReplyHasHateCleanText() {
        let vm = PostDetailViewModel()
        vm.replyText = "Great post!"
        XCTAssertFalse(vm.replyHasHate)
    }

    func testReplyHasHateWithSlur() {
        let vm = PostDetailViewModel()
        vm.replyText = "shut up faggot"
        XCTAssertTrue(vm.replyHasHate)
    }

    func testReplyHasHateEmptyText() {
        let vm = PostDetailViewModel()
        vm.replyText = ""
        XCTAssertFalse(vm.replyHasHate)
    }
}
