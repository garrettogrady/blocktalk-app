import XCTest
@testable import BlockTalk

final class ReplyTreeTests: XCTestCase {

    private let service = ReplyService()

    func testEmptyInputReturnsEmpty() {
        let tree = service.buildTree(from: [])
        XCTAssertTrue(tree.isEmpty)
    }

    func testSingleRootReply() {
        let reply = TestFixtures.makeReply(parentReplyId: nil, depth: 0)
        let tree = service.buildTree(from: [reply])

        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].id, reply.id)
        XCTAssertTrue(tree[0].children?.isEmpty ?? true)
    }

    func testRootAndChildNested() {
        let rootId = UUID()
        let root = TestFixtures.makeReply(id: rootId, parentReplyId: nil, depth: 0)
        let child = TestFixtures.makeReply(parentReplyId: rootId, depth: 1)
        let tree = service.buildTree(from: [root, child])

        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].children?.count, 1)
        XCTAssertEqual(tree[0].children?[0].id, child.id)
    }

    func testThreeLevelNesting() {
        let rootId = UUID()
        let childId = UUID()
        let root = TestFixtures.makeReply(id: rootId, parentReplyId: nil, depth: 0)
        let child = TestFixtures.makeReply(id: childId, parentReplyId: rootId, depth: 1)
        let grandchild = TestFixtures.makeReply(parentReplyId: childId, depth: 2)

        let tree = service.buildTree(from: [root, child, grandchild])

        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].children?.count, 1)
        XCTAssertEqual(tree[0].children?[0].children?.count, 1)
        XCTAssertEqual(tree[0].children?[0].children?[0].id, grandchild.id)
    }

    func testMultipleRoots() {
        let root1 = TestFixtures.makeReply(parentReplyId: nil, text: "root1", depth: 0)
        let root2 = TestFixtures.makeReply(parentReplyId: nil, text: "root2", depth: 0)
        let tree = service.buildTree(from: [root1, root2])

        XCTAssertEqual(tree.count, 2)
    }

    func testMultipleChildrenUnderSameParent() {
        let rootId = UUID()
        let root = TestFixtures.makeReply(id: rootId, parentReplyId: nil, depth: 0)
        let child1 = TestFixtures.makeReply(parentReplyId: rootId, text: "child1", depth: 1)
        let child2 = TestFixtures.makeReply(parentReplyId: rootId, text: "child2", depth: 1)

        let tree = service.buildTree(from: [root, child1, child2])

        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].children?.count, 2)
    }

    func testOrphanReplyBecomesRoot() {
        // parent_reply_id points to a non-existent UUID
        let orphan = TestFixtures.makeReply(parentReplyId: UUID(), depth: 1)
        let tree = service.buildTree(from: [orphan])

        // orphan's parent doesn't exist, so it becomes a root
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].id, orphan.id)
    }

    func testPreservesReplyOrder() {
        let rootId = UUID()
        let root = TestFixtures.makeReply(id: rootId, parentReplyId: nil, depth: 0)
        let child1 = TestFixtures.makeReply(parentReplyId: rootId, text: "first", depth: 1)
        let child2 = TestFixtures.makeReply(parentReplyId: rootId, text: "second", depth: 1)

        let tree = service.buildTree(from: [root, child1, child2])
        XCTAssertEqual(tree[0].children?[0].text, "first")
        XCTAssertEqual(tree[0].children?[1].text, "second")
    }
}
