import Foundation

@Observable
final class SearchViewModel {
    var query = ""
    var results: [Post] = []
    var isSearching = false
    var error: String?
    var scope: SearchScope = .neighborhood
    /// Same four orderings as the feed, so search and feed read identically.
    var sort: PostSort = .newest

    private let postService = PostService()

    enum SearchScope {
        case neighborhood
        case global
    }

    func search(neighborhoodId: UUID?) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            results = []
            error = nil
            return
        }

        isSearching = true
        error = nil
        defer { isSearching = false }

        do {
            let orderColumn: String
            let ascending: Bool
            switch sort {
            case .newest:       orderColumn = "created_at"; ascending = false
            case .oldest:       orderColumn = "created_at"; ascending = true
            case .mostLiked:    orderColumn = "score";      ascending = false
            case .mostDisliked: orderColumn = "score";      ascending = true
            }

            // Filters must be applied before transforms (.order/.limit)
            // Escape LIKE wildcards so a query like "50% off" or "a_b" matches those
            // literal characters instead of acting as SQL pattern wildcards.
            let escaped = q
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")
            var filterBuilder = supabase.from("posts")
                .select(PostService.postSelect)
                .ilike("text", value: "%\(escaped)%")
                .eq("status", value: "live")

            if scope == .neighborhood, let nid = neighborhoodId {
                filterBuilder = filterBuilder.eq("neighborhood_id", value: nid.uuidString)
            }

            let found: [Post] = try await filterBuilder
                .order(orderColumn, ascending: ascending)
                .limit(50)
                .execute()
                .value
            // Drop a stale response if the user kept typing.
            guard q == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            results = found
        } catch {
            print("Search failed: \(error)")
            self.error = "Search failed. Check your connection and try again."
        }
    }
}
