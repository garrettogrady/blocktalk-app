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

    func search(neighborhoodId: UUID?) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else {
            results = []
            return
        }

        // Bundled mock data (no backend): neighborhood scope = the LES feed;
        // global scope = feed + cross-NYC trending + prompt responses.
        let pool: [Post] = scope == .neighborhood
            ? Post.sampleFeed
            : (Post.sampleFeed + Post.sampleTrending + DailyPrompt.sampleResponses)

        var matched = pool.filter { $0.text.lowercased().contains(q) }
        switch sort {
        case .recent:  matched.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .engaged: matched.sort { $0.score > $1.score }
        }
        results = matched
    }
}
