import Foundation

struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let neighborhoodId: UUID
    var text: String
    var imageUrl: String?
    var pinId: UUID?
    var isDailyPrompt: Bool
    var dailyPromptId: UUID?
    var score: Int
    var upvoteCount: Int
    var downvoteCount: Int
    var replyCount: Int
    var reportCount: Int
    var status: PostStatus
    /// Why the post was removed/flagged, when moderation recorded one. Nil today
    /// (no `moderation_reason` column yet) → the tombstone shows a neutral "guideline
    /// violation" instead of a hardcoded (and often wrong) reason. Decodes the real
    /// reason automatically once the backend adds the column.
    var moderationReason: String?
    var createdAt: Date?
    /// Edit history (00024). original_text is captured once, on the first edit
    /// after engagement, and never overwritten. editedAt set means "show the tag".
    var originalText: String?
    var editedAt: Date?
    var editCount: Int?
    /// Embedded author (username / number / home short code) when the fetch
    /// joins `users`. Nil for plain selects.
    var author: PostAuthor?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case neighborhoodId = "neighborhood_id"
        case text
        case imageUrl = "image_url"
        case pinId = "pin_id"
        case isDailyPrompt = "is_daily_prompt"
        case dailyPromptId = "daily_prompt_id"
        case score
        case upvoteCount = "upvote_count"
        case downvoteCount = "downvote_count"
        case replyCount = "reply_count"
        case reportCount = "report_count"
        case status
        case moderationReason = "moderation_reason"
        case createdAt = "created_at"
        case originalText = "original_text"
        case editedAt = "edited_at"
        case editCount = "edit_count"
        case author
    }
}

struct PostAuthor: Codable, Hashable, Sendable {
    let username: String?
    let userNumber: Int?
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

    init(username: String?, userNumber: Int?, home: HomeRef?, aura: Int? = nil) {
        self.username = username
        self.userNumber = userNumber
        self.home = home
        self.aura = aura
    }
}

enum PostStatus: String, Codable, Sendable {
    case live
    case underReview = "under_review"
    case removed
    /// Deleted by the author but kept as a tombstone because replies (or a report) exist.
    case deleted
}

// Convenience for display
extension Post {
    var isStreetComment: Bool { pinId != nil }
}

