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

    func load() async {
        // Bundled mock data — cross-NYC, distinct from the LES feed
        trendingPosts = Post.sampleTrending

        boroughCards = [
            BoroughCardData(borough: "MANHATTAN", posts: [
                BoroughMini(text: "\"the woman walking 9 dogs on Ave A is single-handedly maintaining the EV\"", score: 631, replies: 52),
                BoroughMini(text: "\"someone is selling 'authentic NY pizza' on Bleecker for $1. it is a slice of bread.\"", score: 412, replies: 38),
                BoroughMini(text: "\"the harlem meer in october is the closest manhattan gets to being honest\"", score: 287, replies: 19),
            ]),
            BoroughCardData(borough: "BROOKLYN", posts: [
                BoroughMini(text: "\"every dog at McCarren is a celebrity in a way no human will ever be\"", score: 412, replies: 38),
                BoroughMini(text: "\"the bedford L at 7:42pm is a moving production of 'we have all made choices'\"", score: 364, replies: 41),
                BoroughMini(text: "\"smith st has 4 cafes named after the same feeling and i have been to all of them\"", score: 218, replies: 17),
            ]),
            BoroughCardData(borough: "QUEENS", posts: [
                BoroughMini(text: "\"jackson heights has the best food per square foot and i won't be arguing\"", score: 287, replies: 22),
                BoroughMini(text: "\"the 7 train above 61st-Woodside at sunset is the most underrated view in NYC\"", score: 241, replies: 33),
                BoroughMini(text: "\"saw a guy on the M60 SBS reading a hard copy of 'The Power Broker' and i wanted to shake his hand\"", score: 156, replies: 12),
            ]),
            BoroughCardData(borough: "BRONX", posts: [
                BoroughMini(text: "\"the d train tonight is a personal attack\"", score: 192, replies: 14),
                BoroughMini(text: "\"a guy on Fordham just sold me three mangoes for $2 and called me 'mami'. i'm emotional.\"", score: 178, replies: 21),
                BoroughMini(text: "\"the yankee stadium 4 train after a loss has its own language\"", score: 134, replies: 18),
            ]),
            BoroughCardData(borough: "STATEN ISLAND", posts: [
                BoroughMini(text: "\"the ferry at 6:42pm is the most peace i've felt all week\"", score: 88, replies: 9),
                BoroughMini(text: "\"snug harbor at golden hour is what staten island has been hiding from manhattanites for a century\"", score: 67, replies: 7),
                BoroughMini(text: "\"the SIM1 bus is just 90 minutes of suburban regret followed by 4 minutes of skyline glory\"", score: 54, replies: 11),
            ]),
        ]

        neighborhoods = [
            DiscoverNeighborhood(name: "Astoria", borough: "QUEENS", talking: 88),
            DiscoverNeighborhood(name: "Crown Heights", borough: "BROOKLYN", talking: 134),
            DiscoverNeighborhood(name: "Inwood", borough: "MANHATTAN", talking: 41),
            DiscoverNeighborhood(name: "Bedford-Stuyvesant", borough: "BROOKLYN", talking: 162),
            DiscoverNeighborhood(name: "Sunnyside", borough: "QUEENS", talking: 27),
        ]
    }
}
