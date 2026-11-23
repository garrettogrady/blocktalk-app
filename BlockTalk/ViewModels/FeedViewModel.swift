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
            // A cancelled load (view went away mid-fetch) is not a failure and
            // must not put up the "Something went wrong" screen.
            if !Self.isCancellation(error) {
                self.error = error.localizedDescription
            }
        }

        isLoading = false
    }

    private static func isCancellation(_ error: Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
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

    /// Quiet re-fetch: no spinner, and the current list stays on screen until
    /// the new one arrives. Used by pull-to-refresh, returning from a post, and
    /// returning to the app, so counts (replies, votes) catch up.
    ///
    /// The fetch runs in its own task on purpose. SwiftUI cancels the
    /// pull-to-refresh task when the view re-renders mid-gesture; that used to
    /// cancel the request, which surfaced as "Something went wrong" over an
    /// empty feed. A failed quiet refresh keeps whatever is already showing.
    func refresh() async {
        guard let neighborhood = viewingNeighborhood else { return }
        let sort = self.sort
        let service = postService
        let fetch = Task { try await service.fetchPosts(neighborhoodId: neighborhood.id, sort: sort) }
        do {
            let fresh = try await fetch.value
            // Drop the result if the user switched neighborhood or sort meanwhile.
            guard viewingNeighborhood?.id == neighborhood.id, self.sort == sort else { return }
            posts = fresh
            error = nil
        } catch {
            if posts.isEmpty && !Self.isCancellation(error) {
                self.error = error.localizedDescription
            }
        }
    }
}
