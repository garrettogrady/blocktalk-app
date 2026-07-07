import Foundation

struct BlockTalkUser: Codable, Identifiable, Sendable {
    let id: UUID
    var username: String
    var userNumber: Int
    var homeNeighborhoodId: UUID?
    var homeChangedAt: Date?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case userNumber = "user_number"
        case homeNeighborhoodId = "home_neighborhood_id"
        case homeChangedAt = "home_changed_at"
        case createdAt = "created_at"
    }

    /// The bundled mock's current user (sampleMe: @BlockTalker #4,827, home LES)
    static let sample = BlockTalkUser(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        username: "BlockTalker",
        userNumber: 4827,
        homeNeighborhoodId: Post.lesNeighborhoodId,
        homeChangedAt: nil,
        createdAt: Date()
    )
}
