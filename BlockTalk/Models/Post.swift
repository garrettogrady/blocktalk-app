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
