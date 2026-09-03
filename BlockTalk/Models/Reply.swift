import Foundation

struct Reply: Codable, Identifiable, Sendable {
    // var (not let) so an optimistic reply's client id can be reconciled to the real
    // DB id once the insert returns (see PostDetailViewModel.reconcileId).
    var id: UUID
    let postId: UUID
    var parentReplyId: UUID?
    let userId: UUID
    let text: String
    var score: Int
    var upvoteCount: Int
    var downvoteCount: Int
    var depth: Int
    var createdAt: Date?
    var children: [Reply]?
    /// Embedded author from the Supabase join on users table.
    var author: ReplyAuthor?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case parentReplyId = "parent_reply_id"
        case userId = "user_id"
        case text, score
        case upvoteCount = "upvote_count"
        case downvoteCount = "downvote_count"
        case depth
        case createdAt = "created_at"
        case author
    }

    static let maxDepth = 3
}

struct ReplyAuthor: Codable, Hashable, Sendable {
    let username: String
    let userNumber: Int
    let home: HomeRef?

    struct HomeRef: Codable, Hashable, Sendable {
        let shortCode: String?
        enum CodingKeys: String, CodingKey { case shortCode = "short_code" }
    }

    enum CodingKeys: String, CodingKey {
        case username
        case userNumber = "user_number"
        case home
    }

    var homeShortCode: String { home?.shortCode ?? "NYC" }

    init(username: String, userNumber: Int, homeShortCode: String) {
        self.username = username
        self.userNumber = userNumber
        self.home = HomeRef(shortCode: homeShortCode)
    }
}
