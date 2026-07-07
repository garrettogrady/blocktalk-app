import Foundation

struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let neighborhoodId: UUID
    let text: String
    var imageUrl: String?
    var pinId: UUID?
    var isDailyPrompt: Bool
    var dailyPromptId: UUID?
    var score: Int
    var replyCount: Int
    var reportCount: Int
    var status: PostStatus
    var createdAt: Date?
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
        case replyCount = "reply_count"
        case reportCount = "report_count"
        case status
        case createdAt = "created_at"
        case author
    }
}

struct PostAuthor: Codable, Hashable, Sendable {
    let username: String?
    let userNumber: Int?
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
}

enum PostStatus: String, Codable, Sendable {
    case live
    case underReview = "under_review"
    case removed
}

// Convenience for display
extension Post {
    var isStreetComment: Bool { pinId != nil }
}
