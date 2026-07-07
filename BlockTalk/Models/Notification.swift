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

// MARK: - Bundled mock notifications
extension BTNotification {
    private static func n(_ kind: String, _ title: String, _ preview: String?, agoMin: Double, unread: Bool) -> BTNotification {
        BTNotification(id: UUID(), userId: UUID(), kind: kind, title: title,
                       preview: preview, unread: unread,
                       createdAt: Date().addingTimeInterval(-agoMin * 60))
    }

    static let samples: [BTNotification] = [
        n("reply", "@deli_truther replied to your post", "the pickles are a Sysco thing, i looked into it", agoMin: 10, unread: true),
        n("vote", "Your post is gaining traction", "▲ 47 and climbing on \"saturday 3am on Ludlow…\"", agoMin: 60, unread: true),
        n("moderation", "A post of yours was restored", "It didn't break the guidelines — it's back up. We'll leave it alone.", agoMin: 120, unread: true),
        n("reply", "@ratking replied to your reply", "Glenn says hi", agoMin: 1440, unread: false),
        n("vote", "@forsyth and 11 others voted on your post", nil, agoMin: 2880, unread: false),
    ]

    static var unreadCount: Int { samples.filter(\.unread).count }
}
