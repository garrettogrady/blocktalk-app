import Foundation

@Observable
final class SearchViewModel {
    var query = ""
    var results: [Post] = []
    var isSearching = false
    var scope: SearchScope = .neighborhood
    var sort: SearchSort = .recent

    enum SearchScope {
        case neighborhood
        case global
    }

    enum SearchSort: String, CaseIterable {
        case recent = "Recent"
        case engaged = "Most engaged"
    }

    private let postService = PostService()

    func search(neighborhoodId: UUID?) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        isSearching = true

        do {
            // Build the query, applying sort before executing
            var queryBuilder = supabase.from("posts")
                .select(PostService.postSelect)
                .ilike("text", pattern: "%\(trimmed)%")
                .eq("status", value: "live")

            if scope == .neighborhood, let neighborhoodId {
                queryBuilder = queryBuilder.eq("neighborhood_id", value: neighborhoodId.uuidString)
            }

            // .order() returns PostgrestTransformBuilder, so chain directly into execute
            let ordered = switch sort {
            case .recent:
                queryBuilder.order("created_at", ascending: false)
            case .engaged:
                queryBuilder.order("score", ascending: false)
            }

            results = try await ordered.limit(50).execute().value
        } catch {
            results = []
        }

        isSearching = false
    }
}
