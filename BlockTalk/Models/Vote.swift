import Foundation

struct Vote: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var postId: UUID?
    var replyId: UUID?
    let direction: Int // -1 or 1
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case replyId = "reply_id"
        case direction
        case createdAt = "created_at"
    }
}
