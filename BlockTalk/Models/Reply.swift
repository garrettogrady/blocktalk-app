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
