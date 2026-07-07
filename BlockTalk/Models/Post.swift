import Foundation

struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let neighborhoodId: UUID
    let text: String
    var imageUrl: String?
    var pinId: UUID?
    var isDailyPrompt: Bool
    var dailyPromptId: UUID?
    var score: Int
    var replyCount: Int
    var reportCount: Int
    var status: PostStatus
    var createdAt: Date?
    /// Embedded author (username / number / home short code) when the fetch
    /// joins `users`. Nil for plain selects.
    var author: PostAuthor?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case neighborhoodId = "neighborhood_id"
        case text
        case imageUrl = "image_url"
        case pinId = "pin_id"
        case isDailyPrompt = "is_daily_prompt"
        case dailyPromptId = "daily_prompt_id"
        case score
        case replyCount = "reply_count"
        case reportCount = "report_count"
        case status
        case createdAt = "created_at"
        case author
    }
}

struct PostAuthor: Codable, Hashable, Sendable {
    let username: String?
    let userNumber: Int?
    let home: HomeRef?

    struct HomeRef: Codable, Hashable, Sendable {
        let shortCode: String?
        enum CodingKeys: String, CodingKey { case shortCode = "short_code" }
    }

    enum CodingKeys: String, CodingKey {
        case username
        case userNumber = "user_number"
        case home
    }
}

enum PostStatus: String, Codable, Sendable {
    case live
    case underReview = "under_review"
    case removed
}

// Convenience for display
extension Post {
    var isStreetComment: Bool { pinId != nil }
}

// MARK: - Bundled mock data (mirrors the Expo mock's src/data/samplePosts.ts)
// Local sample content so the app populates with no backend. Garrett re-points
// the services at Supabase for the real build.
extension Post {
    /// Stable LES neighborhood id shared by the sample user + posts
    static let lesNeighborhoodId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    private static func sample(_ username: String, _ number: Int, _ text: String,
                               agoMin: Double, score: Int, replies: Int,
                               pinId: UUID? = nil, image: String? = nil) -> Post {
        Post(
            id: UUID(),
            userId: UUID(),
            neighborhoodId: lesNeighborhoodId,
            text: text,
            imageUrl: image,
            pinId: pinId,
            isDailyPrompt: false,
            score: score,
            replyCount: replies,
            reportCount: 0,
            status: .live,
            createdAt: Date().addingTimeInterval(-agoMin * 60),
            author: PostAuthor(username: username, userNumber: number, home: .init(shortCode: "LES"))
        )
    }

    /// The 34 LES feed posts, in feed order, verbatim from the mock.
    static let sampleFeed: [Post] = [
        sample("twobridges", 618, "the dollar slice place on Allen finally raised it to $1.50 and somehow everyone is taking it harder than the last election", agoMin: 4, score: 96, replies: 27),
        sample("ratking", 1209, "rat ran across my foot on Orchard tonight. paused. looked up at me. continued. it's HIS building actually.", agoMin: 11, score: 84, replies: 12),
        sample("norfolkghost", 2118, "the croissant deli has set up a little folding chair and a sign that says \"fresh at 3am\" and i need an investigation.", agoMin: 45, score: 41, replies: 5, pinId: Pin.stantonNorfolk),
        sample("deli_truther", 812, "someone please tell me why every single deli on Houston has the same pickles", agoMin: 60, score: 88, replies: 14),
        sample("BlockTalker", 3442, "whoever is busking on this corner — please. learn one (1) other song. it's been \"wonderwall\" for six straight weekends.", agoMin: 120, score: 88, replies: 9, pinId: Pin.essexRivington),
        sample("norfolkghost", 2118, "the guy outside Beauty & Essex who tries to sell you a \"VIP wristband\" — i feel like he's been working that exact hustle since 2014 and i respect it now", agoMin: 120, score: 64, replies: 31),
        sample("forsyth", 1777, "three years. same Barbour jacket. same cigarette. either a ghost or me.", agoMin: 180, score: 132, replies: 14, pinId: Pin.houstonLudlow),
        sample("clintonst", 441, "unmarked black sedan idling on Clinton with its hazards on for 90 minutes. either a movie shoot nobody told us about or the start of a kidnapping plot.", agoMin: 180, score: 53, replies: 18),
        sample("orchard_walker", 987, "i've started recognizing the same three rats on Rivington. one of them definitely lives in the bodega.", agoMin: 240, score: 201, replies: 56),
        sample("attorney_st", 1558, "unmarked black sedan, hazards on, 90 minutes. either a movie shoot or the prologue to a kidnapping.", agoMin: 300, score: 67, replies: 8, pinId: Pin.delanceyAllen),
        sample("henrystreet", 2341, "Solid gym, think they might want to look into selling deoderant in addition to pre-work out, place is a zoo", agoMin: 60, score: 54, replies: 6, pinId: Pin.clintonDelancey),
        sample("BlockTalker", 3442, "saturday 3am on Ludlow looks like a high school reunion if your high school exclusively graduated finance bros and one (1) bachelorette party.", agoMin: 300, score: 152, replies: 38),
        sample("forsyth", 1777, "i swear to god the same guy in a Barbour jacket has been smoking the same cigarette outside Dimes on Ludlow for three years. either he is a ghost or i am.", agoMin: 420, score: 234, replies: 47),
        sample("ludlow_loiter", 2344, "two girls outside Metrograph just had a fight about whether Sofia Coppola or Greta Gerwig is the better director and one of them threw a hot dog. real hot dog. real velocity.", agoMin: 540, score: 412, replies: 113),
        sample("eldridge", 309, "the cat that lives in the laundromat window on Eldridge has a new bow tie. i need everyone to acknowledge this.", agoMin: 660, score: 167, replies: 38),
        sample("attorney_st", 1558, "overheard at Russ & Daughters: \"i just don't think the smoked sable is communicating with me the way it used to\". sir. it is fish.", agoMin: 840, score: 289, replies: 62),
        sample("ludlow_loiter", 2344, "girl on Stanton at 2:47am, holding a single high heel, on facetime, calmly saying \"no babe i'm fine.\" her shoulders disagree.", agoMin: 900, score: 178, replies: 19),
        sample("eldridge", 309, "Pianos has been waiting on a guy at the door for 11 minutes. eleven. the line behind him started doing yoga.", agoMin: 960, score: 91, replies: 24),
        sample("clintonst", 441, "the bouncer at Local 138 just told a guy \"not because of the shoes. because of the energy.\" sat in my apartment thinking about it for an hour.", agoMin: 1020, score: 207, replies: 41, image: "https://picsum.photos/seed/blocktalk-bouncer/640/480"),
        sample("broomeghost", 2901, "the woman who reads the Post at the Delancey bus stop out loud — not articles. headlines only. with editorial commentary. she has been doing this since 2019 minimum.", agoMin: 1080, score: 244, replies: 33),
        sample("forsyth", 1777, "the guy with the single plastic bag who used to stand outside Schiller's still stands there. Schiller's has been closed for eight years. he predates the building.", agoMin: 1140, score: 168, replies: 22),
        sample("deli_truther", 812, "the deli on Ludlow has \"EGG SANGY $4\" written on a paper plate taped to the door. the sandwich is also $4. they're not lying. they're just tired.", agoMin: 1200, score: 192, replies: 27),
        sample("attorney_st", 1558, "Russ & Daughters at 9:30am on a saturday looks like a Whole Foods crossed with an Apple Store crossed with a Bar Mitzvah and i mean that with love.", agoMin: 1260, score: 221, replies: 44),
        sample("broomeghost", 2901, "Yonah Schimmel hasn't changed the awning since the Eisenhower administration and i respect it more than my own family.", agoMin: 1320, score: 156, replies: 18, image: "https://picsum.photos/seed/blocktalk-awning/640/480"),
        sample("orchard_walker", 987, "Doughnut Plant. 11am. last tray of pistachio. one guy in a hoodie. the way he looked at me when i reached — i let him have it. i'd lose that fight on principle.", agoMin: 1380, score: 134, replies: 29),
        sample("avenuec", 1022, "bodega on Norfolk is selling a single pint of Häagen-Dazs for $14.99 and the cat is sitting on it like she earned the markup.", agoMin: 1440, score: 142, replies: 16),
        sample("ratking", 1209, "saw a rat on Orchard carrying — like physically carrying, in its mouth — half a slice of Joe's. i want to be that ambitious about anything.", agoMin: 1440, score: 287, replies: 51),
        sample("forsyth", 1777, "raccoon on Forsyth at 11pm with the posture of a guy who knows these alleys better than i do. we nodded at each other.", agoMin: 1440, score: 119, replies: 21),
        sample("eldridge", 309, "a girl walked into Dimes Deli, said \"oh i thought this was Dimes Square\" out loud, to no one, and walked back out. i think about her every day.", agoMin: 2880, score: 318, replies: 67),
        sample("broomeghost", 2901, "Tenement Museum tour just walked past my building with the audio guide on speakerphone and i swear to god the guide said \"imagine the smell\" as they passed my trash bags.", agoMin: 2880, score: 256, replies: 38),
        sample("norfolkghost", 2118, "third café on Orchard this year named after a feeling. \"Languid.\" \"Soft.\" \"Hush.\" i'm not living in a neighborhood. i'm living in a candle.", agoMin: 2880, score: 281, replies: 49),
        sample("twobridges", 618, "scaffolding on Rivington just turned 4 years old. somebody bring a cake.", agoMin: 2880, score: 173, replies: 26, image: "https://picsum.photos/seed/blocktalk-scaffold/640/480"),
        sample("clintonst", 441, "the fancy hardware store on Bowery is selling a $48 sponge. it is a sponge. it is the same sponge i can get on Essex for $1.25. but this one is gray.", agoMin: 4320, score: 204, replies: 34),
        sample("avenuec", 1022, "overheard on Clinton: \"i told her, the apartment doesn't get sun, but it gets vibes.\" brother. that's the sun.", agoMin: 4320, score: 341, replies: 58),
    ]

    private static func trend(_ username: String, _ number: Int, _ home: String, _ text: String, agoMin: Double, score: Int, replies: Int) -> Post {
        Post(
            id: UUID(), userId: UUID(), neighborhoodId: UUID(),
            text: text, isDailyPrompt: false, score: score, replyCount: replies,
            reportCount: 0, status: .live,
            createdAt: Date().addingTimeInterval(-agoMin * 60),
            author: PostAuthor(username: username, userNumber: number, home: .init(shortCode: home))
        )
    }

    /// Cross-NYC trending posts for Discover (distinct from the LES feed)
    static let sampleTrending: [Post] = [
        trend("bryantparker", 218, "MIDTOWN", "if you ride the e train past 53rd & 5th and don't briefly question your career path you are not paying attention", agoMin: 22, score: 1234, replies: 89),
        trend("williamsburger", 4118, "WILLYB", "the line at Lilia is now its own neighborhood with its own gentrification debate", agoMin: 38, score: 891, replies: 52),
        trend("astoriaforever", 2041, "ASTORIA", "the q70 SBS to LGA at 4am is just me, three flight attendants, and one guy in a cowboy hat. we have a quiet agreement.", agoMin: 60, score: 743, replies: 67),
        trend("parkslopeparent", 1612, "PARK.SLP", "saw a guy at the food coop arguing with the cheese guy about whether brie is 'colonialist.' i need to leave brooklyn for at least a weekend.", agoMin: 120, score: 712, replies: 134),
        trend("ferrygoer", 588, "ST.GRG", "the staten island ferry guitar guy did wonderwall tonight and the entire upper deck sighed in unison. there is unity here. it's just hidden.", agoMin: 120, score: 698, replies: 41),
        trend("riverdalerat", 912, "B-DALE", "tour bus dumped a group on Arthur Ave and one of them said 'this feels too italian to be real' — brother, that's because it is real.", agoMin: 180, score: 612, replies: 38),
        trend("jackson_hts", 3209, "JCKSN.HTS", "the line at Pio Pio at 9pm on a tuesday is full of people from 14 different boroughs of their own imagination", agoMin: 240, score: 587, replies: 49),
        trend("uppereastsider", 1872, "UES", "the 4 train at 8am sounds like 200 people simultaneously deciding they need a new career", agoMin: 300, score: 541, replies: 88),
        trend("cobblehiller", 702, "COBBLE", "girl on Court St with a smoothie, a notebook, and three different colored pens. she's about to ruin some guy's life. i can feel it.", agoMin: 360, score: 488, replies: 31),
        trend("bushwickdad", 2447, "BUSHWICK", "Maria Hernandez Park at sunset is what people are talking about when they say new york is healing", agoMin: 480, score: 419, replies: 26),
    ]

    private static func pinPost(_ pinId: UUID, _ username: String, _ number: Int, _ text: String, score: Int, replies: Int, agoMin: Double) -> Post {
        Post(
            id: UUID(), userId: UUID(), neighborhoodId: lesNeighborhoodId,
            text: text, pinId: pinId, isDailyPrompt: false, score: score,
            replyCount: replies, reportCount: 0, status: .live,
            createdAt: Date().addingTimeInterval(-agoMin * 60),
            author: PostAuthor(username: username, userNumber: number, home: .init(shortCode: "LES"))
        )
    }

    /// Featured post for each pin (keyed by pin id), for Pin Detail
    static let samplePinPosts: [UUID: Post] = [
        Pin.essexRivington: pinPost(Pin.essexRivington, "BlockTalker", 3442, "whoever is busking on this corner — please. learn one (1) other song. it's been \"wonderwall\" for six straight weekends.", score: 88, replies: 9, agoMin: 120),
        Pin.stantonNorfolk: pinPost(Pin.stantonNorfolk, "norfolkghost", 2118, "the croissant deli has set up a little folding chair and a sign that says \"fresh at 3am\" and i need an investigation.", score: 41, replies: 5, agoMin: 45),
        Pin.houstonLudlow: pinPost(Pin.houstonLudlow, "forsyth", 1777, "three years. same Barbour jacket. same cigarette. either a ghost or me.", score: 132, replies: 14, agoMin: 180),
        Pin.delanceyAllen: pinPost(Pin.delanceyAllen, "attorney_st", 1558, "unmarked black sedan, hazards on, 90 minutes. either a movie shoot or the prologue to a kidnapping.", score: 67, replies: 8, agoMin: 300),
        Pin.clintonDelancey: pinPost(Pin.clintonDelancey, "henrystreet", 2341, "Solid gym, think they might want to look into selling deoderant in addition to pre-work out, place is a zoo", score: 54, replies: 6, agoMin: 60),
    ]
}
