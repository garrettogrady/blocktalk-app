import Foundation

struct PostService {
    /// Embeds the author (username / number / home short code) so cards render
    /// real identity instead of the placeholder default.
    static let postSelect = "*, author:users(username, user_number, home:neighborhoods(short_code))"

    func fetchPosts(neighborhoodId: UUID, sort: PostSort = .newest, limit: Int = 50) async throws -> [Post] {
        var query = supabase.from("posts")
            .select(Self.postSelect)
            .eq("neighborhood_id", value: neighborhoodId.uuidString)
            .eq("status", value: "live")
            .limit(limit)

        switch sort {
        case .newest:
            query = query.order("created_at", ascending: false)
        case .oldest:
            query = query.order("created_at", ascending: true)
        case .mostLiked:
            query = query.order("score", ascending: false)
        case .mostDisliked:
            query = query.order("score", ascending: true)
        }

        return try await query.execute().value
    }

    func fetchPostForPin(_ pinId: UUID) async throws -> Post? {
        let posts: [Post] = try await supabase.from("posts")
            .select(Self.postSelect)
            .eq("pin_id", value: pinId.uuidString)
            .limit(1)
            .execute()
            .value
        return posts.first
    }

    func createPost(_ post: NewPost) async throws -> Post {
        return try await supabase.from("posts")
            .insert(post)
            .select()
            .single()
            .execute()
            .value
    }

    func vote(postId: UUID, userId: UUID, direction: Int) async throws {
        try await supabase.from("votes")
            .upsert([
                "user_id": userId.uuidString,
                "post_id": postId.uuidString,
                "direction": "\(direction)",
            ])
            .execute()
    }

    func removeVote(postId: UUID, userId: UUID) async throws {
        try await supabase.from("votes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("post_id", value: postId.uuidString)
            .execute()
    }

    func report(postId: UUID, reporterId: UUID, reason: String, freeText: String?) async throws {
        var data: [String: String] = [
            "reporter_id": reporterId.uuidString,
            "post_id": postId.uuidString,
            "reason": reason,
        ]
        if let freeText { data["free_text"] = freeText }

        try await supabase.from("reports")
            .insert(data)
            .execute()
    }
}

struct NewPost: Encodable {
    let userId: UUID
    let neighborhoodId: UUID
    let text: String
    var imageUrl: String?
    var pinId: UUID?
    var isDailyPrompt: Bool = false
    var dailyPromptId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case neighborhoodId = "neighborhood_id"
        case text
        case imageUrl = "image_url"
        case pinId = "pin_id"
        case isDailyPrompt = "is_daily_prompt"
        case dailyPromptId = "daily_prompt_id"
    }
}

enum PostSort: String, CaseIterable {
    case newest = "Newest Posts"
    case oldest = "Oldest Posts"
    case mostLiked = "Most Liked"
    case mostDisliked = "Most Disliked"
}

struct DailyPromptService {
    /// The currently-active prompt (now within [active_from, active_until]).
    func fetchActivePrompt() async throws -> DailyPrompt? {
        let nowISO = ISO8601DateFormatter().string(from: Date())
        let prompts: [DailyPrompt] = try await supabase.from("daily_prompts")
            .select()
            .lte("active_from", value: nowISO)
            .gte("active_until", value: nowISO)
            .order("active_from", ascending: false)
            .limit(1)
            .execute()
            .value
        return prompts.first
    }
}

enum TimeFilter: String, CaseIterable {
    case day = "Last 24 hours"
    case week = "Last week"
    case month = "Last month"
    case all = "All time"

    var date: Date? {
        let calendar = Calendar.current
        switch self {
        case .day: return calendar.date(byAdding: .day, value: -1, to: Date())
        case .week: return calendar.date(byAdding: .weekOfYear, value: -1, to: Date())
        case .month: return calendar.date(byAdding: .month, value: -1, to: Date())
        case .all: return nil
        }
    }
}
