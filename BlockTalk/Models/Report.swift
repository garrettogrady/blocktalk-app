import Foundation

struct Report: Codable, Identifiable, Sendable {
    let id: UUID
    let reporterId: UUID
    let postId: UUID
    let reason: String
    var freeText: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case reporterId = "reporter_id"
        case postId = "post_id"
        case reason
        case freeText = "free_text"
        case createdAt = "created_at"
    }
}

enum ReportReason: String, CaseIterable, Identifiable {
    case pii
    case hate
    case threats
    case sexual
    case spam
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pii: "Identifies a specific person"
        case .hate: "Hate speech or slurs"
        case .threats: "Threats or harassment"
        case .sexual: "Sexual or explicit content"
        case .spam: "Spam or off-topic"
        case .other: "Something else"
        }
    }

    var desc: String {
        switch self {
        case .pii: "Names, addresses, apartments, or anything that points at an individual."
        case .hate: "Racism, ethnic stereotypes, slurs."
        case .threats: "Direct threats, targeted harassment."
        case .sexual: "Nudity, sexual content, anything involving minors."
        case .spam: "Bots, ads, commercial promotion."
        case .other: "Tell us what is wrong with this post."
        }
    }

    var short: String {
        switch self {
        case .pii: "identifying an individual"
        case .hate: "hate speech"
        case .threats: "threats or harassment"
        case .sexual: "sexual content"
        case .spam: "spam"
        case .other: "other"
        }
    }
}
