import Foundation

@Observable
final class SearchViewModel {
    var query = ""
    var results: [Post] = []
    var isSearching = false
    var scope: SearchScope = .neighborhood
    var sort: SearchSort = .recent

    private let postService = PostService()

    enum SearchScope {
        case neighborhood
        case global
    }

    enum SearchSort: String, CaseIterable {
        case recent = "Recent"
        case engaged = "Most engaged"
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
            let orderColumn = sort == .recent ? "created_at" : "score"

            // Filters must be applied before transforms (.order/.limit)
            var filterBuilder = supabase.from("posts")
                .select(PostService.postSelect)
                .ilike("text", value: "%\(q)%")
                .eq("status", value: "live")

            if scope == .neighborhood, let nid = neighborhoodId {
                filterBuilder = filterBuilder.eq("neighborhood_id", value: nid.uuidString)
            }

            results = try await filterBuilder
                .order(orderColumn, ascending: false)
                .limit(50)
                .execute()
                .value
        } catch {
            print("Search failed: \(error)")
            results = []
        }
    }
}
