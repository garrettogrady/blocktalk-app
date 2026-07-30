import Foundation

struct PostService {
    /// Embeds the author (username / number / home short code) so cards render
    /// real identity instead of the placeholder default.
    static let postSelect = "*, author:users!posts_user_id_fkey(username, user_number, home:neighborhoods(short_code))"

    func fetchPosts(neighborhoodId: UUID, sort: PostSort = .newest, limit: Int = 50) async throws -> [Post] {
        let orderColumn: String
        let ascending: Bool
        switch sort {
        case .newest:       orderColumn = "created_at"; ascending = false
        case .oldest:       orderColumn = "created_at"; ascending = true
        case .mostLiked:    orderColumn = "score";      ascending = false
        case .mostDisliked: orderColumn = "score";      ascending = true
        }
        let ordered = supabase.from("posts")
            .select(PostService.postSelect)
            .eq("neighborhood_id", value: neighborhoodId.uuidString)
            .eq("status", value: "live")
            .order(orderColumn, ascending: ascending)
        // Score sorts tie constantly (lots of 0/1-score posts) — break ties by
        // recency so the list is stable instead of reshuffling each fetch.
        // NOTE: "Most Disliked" ranks by *lowest net score*, which is only a
        // rough proxy. A true most-downvoted ordering needs a real downvote
        // tally on the payload — that's the backend voting item (handoff §1).
        let query = (sort == .mostLiked || sort == .mostDisliked)
            ? ordered.order("created_at", ascending: false)
            : ordered
        return try await query
            .limit(limit)
            .execute()
            .value
    }

    func fetchPost(id: UUID) async throws -> Post? {
        let posts: [Post] = try await supabase.from("posts")
            .select(PostService.postSelect)
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return posts.first
    }

    func fetchPostForPin(_ pinId: UUID) async throws -> Post? {
        let posts: [Post] = try await supabase.from("posts")
            .select(PostService.postSelect)
            .eq("pin_id", value: pinId.uuidString)
            .eq("status", value: "live")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return posts.first
    }

    func createPost(_ post: NewPost) async throws -> Post {
        return try await supabase.from("posts")
            .insert(post)
            .select(PostService.postSelect)
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
        let now = ISO8601DateFormatter().string(from: Date())
        let prompts: [DailyPrompt] = try await supabase.from("daily_prompts")
            .select()
            .lte("active_from", value: now)
            .gte("active_until", value: now)
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
