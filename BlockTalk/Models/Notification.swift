import Foundation

struct BTNotification: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let kind: String
    let title: String
    var preview: String?
    var meta: String?
    var unread: Bool
    var relatedPostId: UUID?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case kind, title, preview, meta, unread
        case relatedPostId = "related_post_id"
        case createdAt = "created_at"
    }
}

