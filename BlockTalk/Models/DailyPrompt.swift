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

    static let sampleAnswerCount = 1842

    private static func resp(_ username: String, _ number: Int, _ home: String, _ text: String, agoMin: Double, score: Int, replies: Int) -> Post {
        Post(id: UUID(), userId: UUID(), neighborhoodId: UUID(), text: text, isDailyPrompt: true,
             score: score, replyCount: replies, reportCount: 0, status: .live,
             createdAt: Date().addingTimeInterval(-agoMin * 60),
             author: PostAuthor(username: username, userNumber: number, home: .init(shortCode: home)))
    }

    /// The 8 cross-NYC responses to today's prompt
    static let sampleResponses: [Post] = [
        resp("lline_lover", 4011, "Williamsburg", "guy on the L last night had a full live peacock on a harness. peacock was unbothered. man was unbothered. i was the only one having a freakout and i was alone in that.", agoMin: 14, score: 2840, replies: 312),
        resp("midtownmuck", 932, "Midtown", "a guy in a full pinstripe suit was IRONING A DRESS SHIRT on the F train this morning. there was an extension cord. to this day i do not know where the extension cord went.", agoMin: 22, score: 4112, replies: 528),
        resp("astoria_hum", 2114, "Astoria", "a woman walked a goat past the dollar pizza on Steinway. the goat had little socks on. nobody else seemed to find this particularly insane and i think about that constantly.", agoMin: 38, score: 1987, replies: 244),
        resp("timessq_obs", 1209, "Midtown", "i watched the Naked Cowboy give a tourist family full GPS-level walking directions to a halal cart while playing the chorus of sweet home alabama. five-star service.", agoMin: 52, score: 3220, replies: 401),
        resp("parkslope_pram", 3776, "Park Slope", "saw a guy with a full real katana on the Q. he had a velvet cleaning cloth out and was wiping it down on his lap like the rest of us were on his commute by mistake.", agoMin: 60, score: 1633, replies: 187),
        resp("motthaven_news", 604, "Mott Haven", "watched a pigeon successfully steal an entire dollar slice off a guy's plate at the bodega counter. he did not even chase it. he respected it. i respected it.", agoMin: 120, score: 2104, replies: 269),
        resp("ratking", 1889, "LES", "i was at a basement bar on Allen and somebody walked in with a penguin. like a real tuxedo party penguin. it had a little harness. the bartender just nodded at it.", agoMin: 180, score: 5021, replies: 612),
        resp("jackson_h", 2901, "Jackson Heights", "two strangers got engaged in line at the Halal Guys at 2am. she said yes. he did not even let her finish her chicken over rice. nyc.", agoMin: 240, score: 1442, replies: 158),
    ]

    /// 3 past prompts (locked from new answers)
    static let sampleArchive: [PromptArchive] = [
        PromptArchive(question: "What's the dumbest thing you overheard on the train today?", date: "YESTERDAY", answerCount: 412, posts: [
            resp("qline_lover", 1902, "Sunnyside", "guy on the 7 confidently explaining to a tourist that the Chrysler Building was \"built by the chrysler family in like the 1700s\"", agoMin: 1440, score: 1289, replies: 134),
            resp("bedfordave", 3021, "Bedford-Stuyvesant", "two girls on the A: \"ok but is it cheating if he's in a different time zone.\" they were having a real and serious conversation.", agoMin: 1440, score: 1842, replies: 211),
            resp("crosstown", 719, "Midtown", "man on the M14 to his AirPods: \"Brenda, I will not say it again, the gnocchi is not for sharing.\"", agoMin: 1440, score: 1554, replies: 187),
        ]),
        PromptArchive(question: "Caught any drama today?", date: "2 DAYS AGO", answerCount: 318, posts: [
            resp("parkslope_pram", 844, "Park Slope", "two moms in matching Athleta nearly came to blows at the Met Foods because one of them said the other's daughter was \"intense for a four-year-old\"", agoMin: 2880, score: 982, replies: 96),
            resp("eastvillgremlin", 2567, "East Village", "a man and his ex broke up again in real time outside Mamoun's. she got the falafel. he got the bill. classic", agoMin: 2880, score: 1322, replies: 142),
            resp("harlembrass", 1448, "Harlem", "a private investigator (he announced his job, repeatedly, very loudly) was getting dumped at Sylvia's. she was so calm. he was not.", agoMin: 2880, score: 711, replies: 78),
        ]),
        PromptArchive(question: "What does your block sound like right now?", date: "3 DAYS AGO", answerCount: 256, posts: [
            resp("crownhts", 3302, "Crown Heights", "someone three buildings down is rehearsing a single phrase on the trumpet. it is going badly. it is also going on hour two.", agoMin: 4320, score: 612, replies: 58),
            resp("wilburtide", 1103, "Williamsburg", "unmuffled motorcycle, then a flock of pigeons, then a woman screaming \"TYLER\" at full volume, then silence. NYC.", agoMin: 4320, score: 1044, replies: 117),
            resp("jackson_h", 2219, "Jackson Heights", "the bachata coming out of the bodega across the street is louder than my own thoughts. genuinely a good time though.", agoMin: 4320, score: 798, replies: 84),
        ]),
    ]

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

struct PromptArchive: Identifiable {
    let id = UUID()
    let question: String
    let date: String
    let answerCount: Int
    let posts: [Post]
}
