import Foundation

@Observable
final class SearchViewModel {
    var query = ""
    var results: [Post] = []
    var isSearching = false
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
            return
        }

        isSearching = true
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
            var filterBuilder = supabase.from("posts")
                .select(PostService.postSelect)
                .ilike("text", value: "%\(q)%")
                .eq("status", value: "live")

            if scope == .neighborhood, let nid = neighborhoodId {
                filterBuilder = filterBuilder.eq("neighborhood_id", value: nid.uuidString)
            }

            results = try await filterBuilder
                .order(orderColumn, ascending: ascending)
                .limit(50)
                .execute()
                .value
        } catch {
            print("Search failed: \(error)")
            results = []
        }
    }
}
