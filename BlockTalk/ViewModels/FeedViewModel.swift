import Foundation

@Observable
final class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false
    var error: String?
    var sort: PostSort = .mostLiked
    var timeFilter: TimeFilter = .day
    var viewingNeighborhood: Neighborhood?
    var dailyPrompt: DailyPrompt?

    private let postService = PostService()

    func loadPosts() async {
        guard let neighborhood = viewingNeighborhood else { return }
        isLoading = true
        error = nil

        do {
            posts = try await postService.fetchPosts(
                neighborhoodId: neighborhood.id,
                sort: sort
            )
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func createPost(text: String, imageUrl: String? = nil, userId: UUID) async {
        guard let neighborhood = viewingNeighborhood else { return }

        do {
            let newPost = NewPost(
                userId: userId,
                neighborhoodId: neighborhood.id,
                text: text,
                imageUrl: imageUrl
            )
            let post = try await postService.createPost(newPost)
            posts.insert(post, at: 0)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func vote(postId: UUID, userId: UUID, direction: Int) async {
        do {
            try await postService.vote(postId: postId, userId: userId, direction: direction)
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].score += direction
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refresh() async {
        await loadPosts()
    }
}
