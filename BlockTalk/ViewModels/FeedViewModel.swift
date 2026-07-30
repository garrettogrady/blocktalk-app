import Foundation

@Observable
final class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false
    var error: String?
    var sort: PostSort = .newest
    var timeFilter: TimeFilter = .day
    var viewingNeighborhood: Neighborhood?
    var dailyPrompt: DailyPrompt?
    /// Real number of responses to the active prompt (drives the card's "N
    /// answers"). Nil until loaded so the card can hide the count rather than
    /// show a fake one.
    var promptAnswerCount: Int?

    private let postService = PostService()
    private let promptService = DailyPromptService()

    /// Fetch the active daily prompt (was never wired — the card couldn't render)
    func loadDailyPrompt() async {
        do {
            dailyPrompt = try await promptService.fetchActivePrompt()
            // Real response count — a HEAD count query, no rows fetched.
            if let promptId = dailyPrompt?.id {
                let response = try await supabase.from("posts")
                    .select("id", head: true, count: .exact)
                    .eq("daily_prompt_id", value: promptId.uuidString)
                    .eq("status", value: "live")
                    .execute()
                promptAnswerCount = response.count
            }
        } catch {
            print("Failed to load daily prompt: \(error)")
        }
    }

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
