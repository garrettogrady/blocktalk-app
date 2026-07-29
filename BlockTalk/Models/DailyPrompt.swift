import Foundation

struct DailyPrompt: Codable, Identifiable, Sendable {
    let id: UUID
    let question: String
    let activeFrom: Date
    let activeUntil: Date
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, question
        case activeFrom = "active_from"
        case activeUntil = "active_until"
        case createdAt = "created_at"
    }

    var isActive: Bool {
        let now = Date()
        return now >= activeFrom && now <= activeUntil
    }

    var timeRemaining: String {
        let now = Date()
        guard activeUntil > now else { return "expired" }
        let interval = activeUntil.timeIntervalSince(now)
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        if days > 0 { return "\(days)d \(hours)h LEFT" }
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 { return "\(hours)h \(String(format: "%02d", minutes))m LEFT" }
        return "\(minutes)m LEFT"
    }
}

struct PromptArchive: Identifiable {
    let id = UUID()
    let question: String
    let date: String
    let answerCount: Int
    let posts: [Post]
}
