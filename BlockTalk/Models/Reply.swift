import Foundation

struct Reply: Codable, Identifiable, Sendable {
    let id: UUID
    let postId: UUID
    var parentReplyId: UUID?
    let userId: UUID
    let text: String
    var score: Int
    var depth: Int
    var createdAt: Date?
    var children: [Reply]?
    /// Embedded author (local mock / future join); nil on plain backend fetch
    var author: ReplyAuthor?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case parentReplyId = "parent_reply_id"
        case userId = "user_id"
        case text, score, depth
        case createdAt = "created_at"
    }

    static let maxDepth = 3
}

struct ReplyAuthor: Codable, Hashable, Sendable {
    let username: String
    let userNumber: Int
    let homeShortCode: String
}

// MARK: - Bundled mock replies
extension Reply {
    private static func make(_ username: String, _ number: Int, _ text: String,
                             agoMin: Double, score: Int, depth: Int, children: [Reply] = []) -> Reply {
        Reply(
            id: UUID(), postId: UUID(), parentReplyId: nil, userId: UUID(),
            text: text, score: score, depth: depth,
            createdAt: Date().addingTimeInterval(-agoMin * 60),
            children: children.isEmpty ? nil : children,
            author: ReplyAuthor(username: username, userNumber: number, homeShortCode: "LES")
        )
    }

    /// A sample thread shown under any post (the mock's per-post threads are
    /// keyed by id; local sample uses one representative thread with nesting).
    static let sampleThread: [Reply] = [
        make("avenuec", 1022, "heard him do \"creep\" once at 11pm, called it the encore. progress.", agoMin: 14, score: 12, depth: 0, children: [
            make("clintonst", 441, "i live a block away. it has invaded my dreams. i sang it to my dog this morning.", agoMin: 8, score: 27, depth: 1),
        ]),
        make("ratking", 1209, "someone is being held against their will in there", agoMin: 22, score: 18, depth: 0),
        make("orchard_walker", 987, "i saw him blink once in 2022. just once.", agoMin: 30, score: 31, depth: 0),
    ]
}
