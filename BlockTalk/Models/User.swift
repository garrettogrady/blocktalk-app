import Foundation

struct BlockTalkUser: Codable, Identifiable, Sendable {
    let id: UUID
    var username: String
    var userNumber: Int
    var homeNeighborhoodId: UUID?
    var homeChangedAt: Date?
    var usernameChangedAt: Date?
    var isSeed: Bool?
    var createdAt: Date?
    /// Cached aura total (maintained server-side). Optional so inserts don't
    /// send it and older payloads still decode.
    var aura: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case aura
        case userNumber = "user_number"
        case homeNeighborhoodId = "home_neighborhood_id"
        case homeChangedAt = "home_changed_at"
        case usernameChangedAt = "username_changed_at"
        case isSeed = "is_seed"
        case createdAt = "created_at"
    }

}
