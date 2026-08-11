import Foundation

struct NotificationPreferences: Codable {
    var userId: UUID
    var masterEnabled: Bool
    var replies: Bool
    var repliedTo: Bool
    var manuallyFollowed: Bool
    var weeklyPrompt: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case masterEnabled = "master_enabled"
        case replies
        case repliedTo = "replied_to"
        case manuallyFollowed = "manually_followed"
        case weeklyPrompt = "weekly_prompt"
    }

    static let defaults = NotificationPreferences(
        userId: UUID(),
        masterEnabled: true,
        replies: true,
        repliedTo: true,
        manuallyFollowed: true,
        weeklyPrompt: true
    )
}
