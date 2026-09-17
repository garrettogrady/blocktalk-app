import Foundation

struct Reply: Codable, Identifiable, Sendable {
    // var (not let) so an optimistic reply's client id can be reconciled to the real
    // DB id once the insert returns (see PostDetailViewModel.reconcileId).
    var id: UUID
    let postId: UUID
    var parentReplyId: UUID?
    let userId: UUID
    var text: String
    var score: Int
    var upvoteCount: Int
    var downvoteCount: Int
    var depth: Int
    var createdAt: Date?
    var children: [Reply]?
    /// nil before 00024 ran; treat as live.
    var status: ReplyStatus?
    var originalText: String?
    var editedAt: Date?
    var editCount: Int?
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
        case status
        case originalText = "original_text"
        case editedAt = "edited_at"
        case editCount = "edit_count"
        case author
    }

    static let maxDepth = 3
    static let textLimit = 500

    var isDeleted: Bool { status == .deleted }

    /// Every reply beneath this one, at any depth.
    var descendantCount: Int {
        (children ?? []).reduce(0) { $0 + 1 + $1.descendantCount }
    }
}

enum ReplyStatus: String, Codable, Sendable {
    case live
    case deleted
}

struct ReplyAuthor: Codable, Hashable, Sendable {
    let username: String
    let userNumber: Int
    let home: HomeRef?
    /// Author's live aura; nil when the fetch didn't include it.
    var aura: Int?

    struct HomeRef: Codable, Hashable, Sendable {
        let shortCode: String?
        enum CodingKeys: String, CodingKey { case shortCode = "short_code" }
    }

    enum CodingKeys: String, CodingKey {
        case username
        case userNumber = "user_number"
        case home
        case aura
    }

    var homeShortCode: String { home?.shortCode ?? "NYC" }

    init(username: String, userNumber: Int, homeShortCode: String, aura: Int? = nil) {
        self.username = username
        self.userNumber = userNumber
        self.home = HomeRef(shortCode: homeShortCode)
        self.aura = aura
    }
}
