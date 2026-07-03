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
        isLoading = true
        // In production, fetch trending posts across all neighborhoods
        // For now, this will be populated from the backend
        isLoading = false
    }
}
