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

    /// The bundled mock's active prompt
    static let sampleActive = DailyPrompt(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        question: "What's the craziest thing you've ever seen in NYC?",
        activeFrom: Date().addingTimeInterval(-2 * 3600),
        activeUntil: Date().addingTimeInterval(22 * 3600)
    )

    var timeRemaining: String {
        let now = Date()
        guard activeUntil > now else { return "expired" }
        let interval = activeUntil.timeIntervalSince(now)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m LEFT"
        }
        return "\(minutes)m LEFT"
    }
}
