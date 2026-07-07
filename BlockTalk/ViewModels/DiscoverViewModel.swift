import Foundation

@Observable
final class DiscoverViewModel {
    var trendingPosts: [Post] = []
    var boroughPosts: [String: [Post]] = [:]
    var randomNeighborhoods: [Neighborhood] = []
    var isLoading = false
    var error: String?

    private let postService = PostService()
    private let neighborhoodService = NeighborhoodService()

    func load() async {
        // Bundled mock data (no backend). Trending = sample feed by score.
        let byScore = Post.sampleFeed.sorted { $0.score > $1.score }
        trendingPosts = byScore
        let boroughs = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
        for (i, b) in boroughs.enumerated() {
            let start = (i * 3) % max(1, byScore.count - 3)
            boroughPosts[b] = Array(byScore[start ..< min(start + 3, byScore.count)])
        }
        randomNeighborhoods = Neighborhood.sampleRandom
    }
}
