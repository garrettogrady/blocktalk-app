import Foundation

struct BoroughCardData: Identifiable {
    let id = UUID()
    let borough: String
    let posts: [Post]   // real posts, so each row can open its detail
}

struct DiscoverNeighborhood: Identifiable {
    let id = UUID()
    let name: String
    let borough: String
}

@Observable
final class DiscoverViewModel {
    var trendingPosts: [Post] = []
    var boroughCards: [BoroughCardData] = []
    var neighborhoods: [DiscoverNeighborhood] = []
    var isLoading = false
    var isLoadingMore = false
    var canLoadMore = true
    var error: String?
    /// Sort for the city-wide feed. Defaults to Most Liked ("top"); the user can
    /// switch it (Newest / Oldest / Most Disliked) via the same control as the feed.
    var sort: PostSort = .mostLiked

    private let postService = PostService()
    private let pageSize = 15

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        await loadFirstPage()
        await loadBoroughCards()
        await loadRandomNeighborhoods()
    }

    // MARK: - City-wide feed (paginated)

    /// First page of the city-wide feed (also used on pull-to-refresh + sort change).
    func loadFirstPage() async {
        do {
            let first = try await postService.fetchCityWide(sort: sort, offset: 0, pageSize: pageSize)
            trendingPosts = first
            canLoadMore = first.count == pageSize   // a full page => there may be more
        } catch {
            self.error = error.localizedDescription
            print("Discover: failed to load city-wide feed — \(error)")
        }
    }

    /// Append the next page — the "Load more" button. Loads forever, a page at a time.
    func loadMore() async {
        guard canLoadMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let next = try await postService.fetchCityWide(
                sort: sort, offset: trendingPosts.count, pageSize: pageSize)
            // Guard against dupes if new posts shifted the window between pages.
            let existing = Set(trendingPosts.map(\.id))
            trendingPosts += next.filter { !existing.contains($0.id) }
            canLoadMore = next.count == pageSize
        } catch {
            print("Discover: failed to load more — \(error)")
        }
    }

    /// Re-fetch from page 1 when the sort changes.
    func reloadTrending() async {
        canLoadMore = true
        await loadFirstPage()
    }

    // MARK: - Top by Borough

    private func loadBoroughCards() async {
        let boroughNames = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
        var cards: [BoroughCardData] = []
        for borough in boroughNames {
            do {
                let posts: [Post] = try await supabase.from("posts")
                    .select(PostService.postSelect + ", neighborhood:neighborhoods!inner(borough)")
                    .eq("status", value: "live")
                    .eq("neighborhood.borough", value: borough)
                    .order("score", ascending: false)
                    .order("created_at", ascending: false)
                    .limit(3)
                    .execute()
                    .value
                if !posts.isEmpty {
                    cards.append(BoroughCardData(borough: borough.uppercased(), posts: posts))
                }
            } catch {
                // Skip boroughs with no posts
            }
        }
        boroughCards = cards
    }

    // MARK: - Random Neighborhoods (truly random, ≥1 post)

    private func loadRandomNeighborhoods() async {
        do {
            let pool = try await postService.neighborhoodsWithPosts()
            // Truly random each visit — shuffle the pool of neighborhoods that
            // actually have posts, then take a handful. Never an empty feed.
            neighborhoods = pool.shuffled().prefix(5).map {
                DiscoverNeighborhood(name: $0.name, borough: $0.borough)
            }
        } catch {
            print("Discover: failed to load random neighborhoods — \(error)")
            neighborhoods = []
        }
    }
}
