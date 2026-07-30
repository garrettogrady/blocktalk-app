import Foundation

struct BoroughMini: Identifiable {
    let id = UUID()
    let text: String
    let score: Int
    let replies: Int
}

struct BoroughCardData: Identifiable {
    let id = UUID()
    let borough: String
    let posts: [BoroughMini]
}

struct DiscoverNeighborhood: Identifiable {
    let id = UUID()
    let name: String
    let borough: String
    let talking: Int
}

@Observable
final class DiscoverViewModel {
    var trendingPosts: [Post] = []
    var boroughCards: [BoroughCardData] = []
    var neighborhoods: [DiscoverNeighborhood] = []
    var isLoading = false
    var error: String?

    private let postService = PostService()

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Trending: top posts by score across all neighborhoods
        do {
            trendingPosts = try await supabase.from("posts")
                .select(PostService.postSelect)
                .eq("status", value: "live")
                .order("score", ascending: false)
                .limit(10)
                .execute()
                .value
        } catch {
            self.error = error.localizedDescription
            print("Discover: failed to load trending — \(error)")
        }

        // Borough cards: top 3 posts per borough
        let boroughNames = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
        var cards: [BoroughCardData] = []
        for borough in boroughNames {
            do {
                let posts: [Post] = try await supabase.from("posts")
                    .select("*, neighborhood:neighborhoods!inner(borough)")
                    .eq("status", value: "live")
                    .eq("neighborhood.borough", value: borough)
                    .order("score", ascending: false)
                    .limit(3)
                    .execute()
                    .value
                let minis = posts.map { BoroughMini(text: $0.text, score: $0.score, replies: $0.replyCount) }
                if !minis.isEmpty {
                    cards.append(BoroughCardData(borough: borough.uppercased(), posts: minis))
                }
            } catch {
                // Skip boroughs with no posts
            }
        }
        boroughCards = cards

        // Active neighborhoods: neighborhoods with recent posts
        do {
            struct ActiveResult: Decodable {
                let name: String
                let borough: String
                let talkingCount: Int
                enum CodingKeys: String, CodingKey {
                    case name, borough
                    case talkingCount = "talking_count"
                }
            }
            let active: [ActiveResult] = try await supabase.rpc("active_neighborhoods")
                .execute()
                .value
            neighborhoods = active.map {
                DiscoverNeighborhood(name: $0.name, borough: $0.borough.uppercased(), talking: $0.talkingCount)
            }
        } catch {
            print("Discover: failed to load active neighborhoods — \(error)")
            neighborhoods = []
        }
    }
}
