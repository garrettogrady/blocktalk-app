import Foundation

struct Reply: Codable, Identifiable, Sendable {
    let id: UUID
    let postId: UUID
    var parentReplyId: UUID?
    let userId: UUID
    let text: String
    var score: Int
    var depth: Int
    var createdAt: Date?
    var children: [Reply]?
    /// Embedded author (local mock / future join); nil on plain backend fetch
    var author: ReplyAuthor?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case parentReplyId = "parent_reply_id"
        case userId = "user_id"
        case text, score, depth
        case createdAt = "created_at"
    }

    static let maxDepth = 3
}

struct ReplyAuthor: Codable, Hashable, Sendable {
    let username: String
    let userNumber: Int
    let homeShortCode: String
}

// MARK: - Bundled mock replies
extension Reply {
    private static func make(_ username: String, _ number: Int, _ text: String,
                             agoMin: Double, score: Int, depth: Int, children: [Reply] = []) -> Reply {
        Reply(
            id: UUID(), postId: UUID(), parentReplyId: nil, userId: UUID(),
            text: text, score: score, depth: depth,
            createdAt: Date().addingTimeInterval(-agoMin * 60),
            children: children.isEmpty ? nil : children,
            author: ReplyAuthor(username: username, userNumber: number, homeShortCode: "LES")
        )
    }

    /// A sample thread shown under any post (the mock's per-post threads are
    /// keyed by id; local sample uses one representative thread with nesting).
    static let sampleThread: [Reply] = [
        make("avenuec", 1022, "heard him do \"creep\" once at 11pm, called it the encore. progress.", agoMin: 14, score: 12, depth: 0, children: [
            make("clintonst", 441, "i live a block away. it has invaded my dreams. i sang it to my dog this morning.", agoMin: 8, score: 27, depth: 1),
        ]),
        make("ratking", 1209, "someone is being held against their will in there", agoMin: 22, score: 18, depth: 0),
        make("orchard_walker", 987, "i saw him blink once in 2022. just once.", agoMin: 30, score: 31, depth: 0),
    ]
}

// MARK: - Per-post reply threads (ported from RN sampleReplies.ts — PRD seed)
// Keyed by post text so it resolves against the bundled sample posts, which use
// runtime-random UUIDs. Generated — do not hand-edit.
extension Reply {
    fileprivate static func rmake(_ username: String, _ number: Int, _ text: String,
                                  agoMin: Double, score: Int, depth: Int,
                                  home: String = "LES", _ children: [Reply] = []) -> Reply {
        Reply(
            id: UUID(), postId: UUID(), parentReplyId: nil, userId: UUID(),
            text: text, score: score, depth: depth,
            createdAt: Date().addingTimeInterval(-agoMin * 60),
            children: children.isEmpty ? nil : children,
            author: ReplyAuthor(username: username, userNumber: number, homeShortCode: home)
        )
    }

    /// Per-post seeded threads. Returns the matching thread for a post's text.
    static func seededThread(forPostText text: String) -> [Reply] {
        threadsByPostText[text.trimmingCharacters(in: .whitespacesAndNewlines)] ?? []
    }

    static let threadsByPostText: [String: [Reply]] = [
        // Hand-authored thread for the gym street comment (street posts weren't in
        // the RN reply seed). Curated onto the feed landing.
        "Solid gym, think they might want to look into selling deoderant in addition to pre-work out, place is a zoo": [
            rmake("clintonst", 441, "the 6pm crowd treats the squat rack like it owes them money. i've made peace with never using it.", agoMin: 12, score: 22, depth: 0, home: "LES", [
                rmake("henrystreet", 2341, "peace is the only gains i've made in there in months.", agoMin: 6, score: 14, depth: 1, home: "LES"),
            ]),
            rmake("orchard_walker", 987, "one guy has been 'about to start his set' on the same bench for twenty minutes. it's not a workout, it's a lifestyle.", agoMin: 20, score: 31, depth: 0, home: "LES"),
            rmake("attorney_st", 1558, "the smell is load-bearing at this point. take it away and the building comes down.", agoMin: 28, score: 27, depth: 0, home: "LES"),
            rmake("broomeghost", 2901, "they sell pre-workout at the front desk but not one stick of deodorant. bold strategy.", agoMin: 34, score: 19, depth: 0, home: "LES"),
        ],
        "rat ran across my foot on Orchard tonight. paused. looked up at me. continued. it's HIS building actually.": [
            rmake("norfolkghost", 2118, "the pause is the most insulting part. he checked you out and concluded you were furniture.", agoMin: 4, score: 47, depth: 0, home: "LES", [rmake("attorney_st", 1558, "the pause IS the entire psychic damage. the running is a footnote.", agoMin: 2, score: 18, depth: 1, home: "LES")]),
            rmake("forsyth", 1777, "he's not paying rent. doesn't have to. he was there first. we are guests in his house.", agoMin: 7, score: 26, depth: 0, home: "LES"),
            rmake("orchard_walker", 987, "what kind of rat. detail matters. there is a hierarchy on orchard and we need to know what we are dealing with.", agoMin: 9, score: 12, depth: 0, home: "LES"),
        ],
        "someone please tell me why every single deli on Houston has the same pickles": [
            rmake("attorney_st", 1558, "one warehouse in queens. one barrel. one man. he is tired.", agoMin: 14, score: 42, depth: 0, home: "LES", [rmake("forsyth", 1777, "pickle cartel is real and i support it", agoMin: 11, score: 19, depth: 1, home: "LES")]),
            rmake("avenuec", 1022, "they all taste like the same regret. it's reassuring honestly.", agoMin: 22, score: 16, depth: 0, home: "LES"),
            rmake("broomeghost", 2901, "the bagel from one is dry, the pickle is identical. variables held constant. science.", agoMin: 30, score: 11, depth: 0, home: "LES"),
        ],
        "the guy outside Beauty & Essex who tries to sell you a \"VIP wristband\" — i feel like he's been working that exact hustle since 2014 and i respect it now": [
            rmake("ludlow_loiter", 2344, "i bought one in 2017. did NOT get into beauty & essex. did get a real wristband. i still have it. it's honestly more sentimental than i expected.", agoMin: 18, score: 58, depth: 0, home: "LES", [rmake("eldridge", 309, "this is the most LES sentence ever written", agoMin: 14, score: 22, depth: 1, home: "LES"), rmake("clintonst", 441, "frame it. it's a relic.", agoMin: 12, score: 7, depth: 1, home: "LES")]),
            rmake("forsyth", 1777, "consistency in this neighborhood is rarer than a rent freeze. let the man eat.", agoMin: 34, score: 29, depth: 0, home: "LES"),
        ],
        "unmarked black sedan idling on Clinton with its hazards on for 90 minutes. either a movie shoot nobody told us about or the start of a kidnapping plot.": [
            rmake("orchard_walker", 987, "it's a movie shoot. it's always a movie shoot. the trailers are around the corner on suffolk.", agoMin: 16, score: 47, depth: 0, home: "LES", [rmake("deli_truther", 812, "or it's a kidnapping AND a movie shoot. nyc is efficient.", agoMin: 13, score: 26, depth: 1, home: "LES", [rmake("avenuec", 1022, "two for one. love this city.", agoMin: 11, score: 9, depth: 2, home: "LES")])]),
            rmake("norfolkghost", 2118, "the hazards are the giveaway. real kidnappers have functional turn signals.", agoMin: 28, score: 33, depth: 0, home: "LES"),
        ],
        "i've started recognizing the same three rats on Rivington. one of them definitely lives in the bodega.": [
            rmake("ratking", 1209, "one is the boss. one is the muscle. one is doing an internship. you can tell by the posture.", agoMin: 20, score: 88, depth: 0, home: "LES", [rmake("attorney_st", 1558, "we need to name them. propose: Phil, Donna, Glenn.", agoMin: 17, score: 41, depth: 1, home: "LES", [rmake("twobridges", 618, "Glenn is absolutely the intern", agoMin: 14, score: 19, depth: 2, home: "LES")])]),
            rmake("broomeghost", 2901, "the bodega cat tolerates them. that's a treaty situation.", agoMin: 40, score: 26, depth: 0, home: "LES"),
        ],
        "saturday 3am on Ludlow looks like a high school reunion if your high school exclusively graduated finance bros and one (1) bachelorette party.": [
            rmake("ludlow_loiter", 2344, "the one bachelorette is the bracelet operator. she's been there every weekend since may. she's a fixture now.", agoMin: 12, score: 64, depth: 0, home: "LES", [rmake("eldridge", 309, "she's the mayor of saturday. nobody elected her. she's just THERE.", agoMin: 9, score: 28, depth: 1, home: "LES")]),
            rmake("clintonst", 441, "what's wild is the finance bros are always wearing the same exact half-zip. there's a uniform code i was not briefed on.", agoMin: 24, score: 41, depth: 0, home: "LES"),
            rmake("deli_truther", 812, "i counted 4 separate vests with company logos last weekend. it's a corporate retreat that never ends and the conference is Ludlow.", agoMin: 38, score: 33, depth: 0, home: "LES"),
        ],
        "the dollar slice place on Allen finally raised it to $1.50 and somehow everyone is taking it harder than the last election": [
            rmake("deli_truther", 812, "50% inflation overnight. they need a bailout. i need a slice.", agoMin: 11, score: 73, depth: 0, home: "LES", [rmake("eldridge", 309, "congress hearing when", agoMin: 8, score: 24, depth: 1, home: "LES")]),
            rmake("forsyth", 1777, "i'm fine paying $1.50 i'm not fine being lied to about what era we live in", agoMin: 22, score: 51, depth: 0, home: "LES"),
            rmake("attorney_st", 1558, "two bites a slice. i'm doing math now. this is what they wanted.", agoMin: 36, score: 18, depth: 0, home: "LES"),
        ],
        "i swear to god the same guy in a Barbour jacket has been smoking the same cigarette outside Dimes on Ludlow for three years. either he is a ghost or i am.": [
            rmake("ludlow_loiter", 2344, "i've seen him too. i thought i was hallucinating. the cigarette never gets shorter.", agoMin: 19, score: 95, depth: 0, home: "LES", [rmake("orchard_walker", 987, "someone needs to walk up and ask him for the time. test the veil.", agoMin: 15, score: 37, depth: 1, home: "LES", [rmake("avenuec", 1022, "i did. he said 8:14. it was 11:30. so.", agoMin: 12, score: 56, depth: 2, home: "LES")])]),
            rmake("broomeghost", 2901, "every neighborhood has one. ours has at least four. he's just the most photogenic.", agoMin: 33, score: 22, depth: 0, home: "LES"),
        ],
        "two girls outside Metrograph just had a fight about whether Sofia Coppola or Greta Gerwig is the better director and one of them threw a hot dog. real hot dog. real velocity.": [
            rmake("attorney_st", 1558, "who threw the hot dog. that's the only relevant detail. which one defended sofia coppola with PROJECTILE FOOD.", agoMin: 8, score: 188, depth: 0, home: "LES", [rmake("eldridge", 309, "has to be the coppola fan. greta fans throw books, not meat.", agoMin: 6, score: 94, depth: 1, home: "LES", [rmake("forsyth", 1777, "this is the most accurate generalization i have ever read", agoMin: 4, score: 48, depth: 2, home: "LES")]), rmake("twobridges", 618, "lady bird could have prevented this", agoMin: 5, score: 31, depth: 1, home: "LES")]),
            rmake("ratking", 1209, "i need the velocity in mph. for science.", agoMin: 22, score: 67, depth: 0, home: "LES"),
            rmake("clintonst", 441, "the hot dog is a metaphor. the hot dog is also a hot dog.", agoMin: 34, score: 29, depth: 0, home: "LES"),
        ],
        "the cat that lives in the laundromat window on Eldridge has a new bow tie. i need everyone to acknowledge this.": [
            rmake("norfolkghost", 2118, "ACKNOWLEDGED. it's navy. it's an upgrade. the red was getting tired.", agoMin: 17, score: 84, depth: 0, home: "LES", [rmake("orchard_walker", 987, "navy is the right call for spring. she knows.", agoMin: 13, score: 31, depth: 1, home: "LES")]),
            rmake("broomeghost", 2901, "her instagram has the bow tie content if you're curious. it's well-lit.", agoMin: 29, score: 42, depth: 0, home: "LES", [rmake("deli_truther", 812, "WAIT. she has an instagram??", agoMin: 25, score: 19, depth: 1, home: "LES")]),
            rmake("attorney_st", 1558, "i waved at her this morning. she did the slow blink. we're fine.", agoMin: 44, score: 27, depth: 0, home: "LES"),
        ],
        "overheard at Russ & Daughters: \"i just don't think the smoked sable is communicating with me the way it used to\". sir. it is fish.": [
            rmake("forsyth", 1777, "i overheard \"the lox is too literal today\" last week. it is genuinely a real conversation people have in there.", agoMin: 10, score: 121, depth: 0, home: "LES", [rmake("avenuec", 1022, "too literal??? what does that even mean. i need it. i'll pay.", agoMin: 7, score: 64, depth: 1, home: "LES", [rmake("ratking", 1209, "it means the man has money to lose. that's what it means.", agoMin: 5, score: 39, depth: 2, home: "LES")])]),
            rmake("ludlow_loiter", 2344, "the sable is fine. you are not fine. there is a difference.", agoMin: 24, score: 88, depth: 0, home: "LES"),
            rmake("twobridges", 618, "i need to start eavesdropping there professionally. there is a podcast in here.", agoMin: 40, score: 35, depth: 0, home: "LES"),
        ],
        "girl on Stanton at 2:47am, holding a single high heel, on facetime, calmly saying \"no babe i'm fine.\" her shoulders disagree.": [
            rmake("avenuec", 1022, "she is not fine. the shoulders never lie. the single heel never lies.", agoMin: 780, score: 88, depth: 0, home: "LES"),
            rmake("attorney_st", 1558, "where is the other heel. that's where the story is.", agoMin: 840, score: 54, depth: 0, home: "LES", [rmake("forsyth", 1777, "the other heel is in a yellow cab going to the upper west side without her", agoMin: 780, score: 36, depth: 1, home: "LES")]),
        ],
        "Pianos has been waiting on a guy at the door for 11 minutes. eleven. the line behind him started doing yoga.": [
            rmake("ludlow_loiter", 2344, "11 minutes at pianos. man, that's a full thursday.", agoMin: 900, score: 41, depth: 0, home: "LES"),
            rmake("ratking", 1209, "the guy is arguing about a $20 cover. always. always always.", agoMin: 900, score: 33, depth: 0, home: "LES", [rmake("norfolkghost", 2118, "the cover IS the negotiation. that IS the door experience.", agoMin: 840, score: 19, depth: 1, home: "LES")]),
            rmake("orchard_walker", 987, "i once gave up on the pianos line and walked to local 138. no cover. better music. same regret.", agoMin: 900, score: 24, depth: 0, home: "LES"),
        ],
        "the bouncer at Local 138 just told a guy \"not because of the shoes. because of the energy.\" sat in my apartment thinking about it for an hour.": [
            rmake("forsyth", 1777, "the bouncer is RIGHT. the energy is real. i've been told no for the energy before. i went home and journaled.", agoMin: 960, score: 116, depth: 0, home: "LES"),
            rmake("broomeghost", 2901, "what is the energy. is it the vibes apartment guy. is it me. i need to know.", agoMin: 960, score: 64, depth: 0, home: "LES", [rmake("deli_truther", 812, "if you have to ask, that IS the energy", agoMin: 900, score: 38, depth: 1, home: "LES")]),
        ],
        "the woman who reads the Post at the Delancey bus stop out loud — not articles. headlines only. with editorial commentary. she has been doing this since 2019 minimum.": [
            rmake("ratking", 1209, "she did 'CON ED RATES UP AGAIN. yeah no shit' on tuesday and i nearly applauded.", agoMin: 1020, score: 132, depth: 0, home: "LES"),
            rmake("avenuec", 1022, "she's better at journalism than the post.", agoMin: 1020, score: 78, depth: 0, home: "LES", [rmake("ludlow_loiter", 2344, "she IS the post", agoMin: 960, score: 41, depth: 1, home: "LES")]),
            rmake("eldridge", 309, "she once said 'good for him' about a celebrity divorce. just 'good for him.' i still don't know which side she was on.", agoMin: 1020, score: 56, depth: 0, home: "LES"),
        ],
        "the guy with the single plastic bag who used to stand outside Schiller's still stands there. Schiller's has been closed for eight years. he predates the building.": [
            rmake("broomeghost", 2901, "what's in the bag. i need a citizens investigation.", agoMin: 1080, score: 71, depth: 0, home: "LES", [rmake("clintonst", 441, "do NOT investigate. that's the only thing keeping him here. and us.", agoMin: 1080, score: 49, depth: 1, home: "LES")]),
            rmake("attorney_st", 1558, "the bag is the same bag. that's the unsettling part.", agoMin: 1080, score: 38, depth: 0, home: "LES"),
            rmake("norfolkghost", 2118, "he's a landmark. give him a plaque.", agoMin: 1020, score: 22, depth: 0, home: "LES"),
        ],
        "the deli on Ludlow has \"EGG SANGY $4\" written on a paper plate taped to the door. the sandwich is also $4. they're not lying. they're just tired.": [
            rmake("ludlow_loiter", 2344, "the paper plate IS the menu. it IS the brand. i would not change a thing.", agoMin: 1140, score: 89, depth: 0, home: "LES"),
            rmake("twobridges", 618, "i bought it. it was a really really good egg sangy.", agoMin: 1140, score: 56, depth: 0, home: "LES", [rmake("ratking", 1209, "of course it was. the tiredness is the seasoning.", agoMin: 1080, score: 41, depth: 1, home: "LES")]),
            rmake("norfolkghost", 2118, "they will not raise the price. they will not change the plate. they are an immovable object. respect.", agoMin: 1140, score: 33, depth: 0, home: "LES"),
        ],
        "Russ & Daughters at 9:30am on a saturday looks like a Whole Foods crossed with an Apple Store crossed with a Bar Mitzvah and i mean that with love.": [
            rmake("avenuec", 1022, "the line for the take-a-number machine has its own line. THE LINE HAS A LINE.", agoMin: 1200, score: 102, depth: 0, home: "LES"),
            rmake("forsyth", 1777, "the kids in suits running between sturgeon. that's the part that gets me. they're doing deals.", agoMin: 1200, score: 68, depth: 0, home: "LES", [rmake("deli_truther", 812, "deals are being made. fish is changing hands. i love it here.", agoMin: 1140, score: 34, depth: 1, home: "LES")]),
            rmake("broomeghost", 2901, "i go just to watch. i don't even buy. it's better than theater.", agoMin: 1200, score: 47, depth: 0, home: "LES"),
        ],
        "Yonah Schimmel hasn't changed the awning since the Eisenhower administration and i respect it more than my own family.": [
            rmake("attorney_st", 1558, "the awning is patina. the awning is the building's earned right. do not touch the awning.", agoMin: 1260, score: 64, depth: 0, home: "LES"),
            rmake("clintonst", 441, "the knish situation in there has not changed and that's exactly why it's perfect.", agoMin: 1260, score: 39, depth: 0, home: "LES"),
            rmake("forsyth", 1777, "i ordered a potato knish in 2016 and they handed me one that had been there since 2009. i ate it. i'm fine.", agoMin: 1260, score: 53, depth: 0, home: "LES"),
        ],
        "Doughnut Plant. 11am. last tray of pistachio. one guy in a hoodie. the way he looked at me when i reached — i let him have it. i'd lose that fight on principle.": [
            rmake("eldridge", 309, "the pistachio is worth the fight. i would have died for it.", agoMin: 1320, score: 52, depth: 0, home: "LES", [rmake("ludlow_loiter", 2344, "you would have died with green frosting on your face. an honorable death.", agoMin: 1320, score: 31, depth: 1, home: "LES")]),
            rmake("ratking", 1209, "the hoodie guy is at every drop. he's a pistachio specialist. he's been training.", agoMin: 1320, score: 28, depth: 0, home: "LES"),
            rmake("broomeghost", 2901, "i went on a tuesday at 10am specifically to avoid this fight. they were sold out. i learned nothing.", agoMin: 1320, score: 17, depth: 0, home: "LES"),
        ],
        "bodega on Norfolk is selling a single pint of Häagen-Dazs for $14.99 and the cat is sitting on it like she earned the markup.": [
            rmake("norfolkghost", 2118, "the cat IS the markup. that's the value-add.", agoMin: 1380, score: 71, depth: 0, home: "LES"),
            rmake("forsyth", 1777, "fourteen ninety-nine. for the ice cream AND the cat? i'd say fair.", agoMin: 1380, score: 44, depth: 0, home: "LES", [rmake("avenuec", 1022, "the cat does not come with the pint. i learned this the hard way.", agoMin: 1320, score: 31, depth: 1, home: "LES")]),
        ],
        "saw a rat on Orchard carrying — like physically carrying, in its mouth — half a slice of Joe's. i want to be that ambitious about anything.": [
            rmake("orchard_walker", 987, "this is Glenn. has to be Glenn. the rivington intern is going freelance.", agoMin: 1440, score: 124, depth: 0, home: "LES", [rmake("attorney_st", 1558, "GLENN. our boy. promoted himself.", agoMin: 1440, score: 78, depth: 1, home: "LES")]),
            rmake("twobridges", 618, "the slice was bigger than the rat. that's leadership.", agoMin: 1440, score: 62, depth: 0, home: "LES"),
            rmake("norfolkghost", 2118, "he's been training for that for a year. i've watched him work up from crusts. inspiring honestly.", agoMin: 1440, score: 41, depth: 0, home: "LES"),
        ],
        "raccoon on Forsyth at 11pm with the posture of a guy who knows these alleys better than i do. we nodded at each other.": [
            rmake("broomeghost", 2901, "the nod is everything. the nod IS the lease. you're allowed here now.", agoMin: 1440, score: 58, depth: 0, home: "LES"),
            rmake("deli_truther", 812, "the raccoon population is genuinely up. they have it figured out. they live well.", agoMin: 1440, score: 36, depth: 0, home: "LES", [rmake("clintonst", 441, "they pay no rent. they live well. coincidence?", agoMin: 1440, score: 24, depth: 1, home: "LES")]),
        ],
        "a girl walked into Dimes Deli, said \"oh i thought this was Dimes Square\" out loud, to no one, and walked back out. i think about her every day.": [
            rmake("ludlow_loiter", 2344, "it's the same name. it's two blocks. it's literally right there. and yet.", agoMin: 2880, score: 142, depth: 0, home: "LES"),
            rmake("avenuec", 1022, "she had to verbally narrate her mistake to the entire deli before she left. iconic.", agoMin: 2880, score: 98, depth: 0, home: "LES", [rmake("forsyth", 1777, "the narration is the punishment. she will not survive that memory. i hope she is well.", agoMin: 2880, score: 67, depth: 1, home: "LES")]),
            rmake("attorney_st", 1558, "this is the most LES rite of passage and i love it for her.", agoMin: 2880, score: 51, depth: 0, home: "LES"),
        ],
        "Tenement Museum tour just walked past my building with the audio guide on speakerphone and i swear to god the guide said \"imagine the smell\" as they passed my trash bags.": [
            rmake("eldridge", 309, "the trash IS the museum at this point. they're not wrong.", agoMin: 2880, score: 119, depth: 0, home: "LES", [rmake("broomeghost", 2901, "we're living the exhibit. we're in it.", agoMin: 2880, score: 64, depth: 1, home: "LES")]),
            rmake("forsyth", 1777, "they had a guy take a photo of my stoop. like a real photo. with intention. i was ON the stoop.", agoMin: 2880, score: 87, depth: 0, home: "LES"),
            rmake("ratking", 1209, "we are now historical artifacts. add us to the wing.", agoMin: 2880, score: 46, depth: 0, home: "LES"),
        ],
        "third café on Orchard this year named after a feeling. \"Languid.\" \"Soft.\" \"Hush.\" i'm not living in a neighborhood. i'm living in a candle.": [
            rmake("deli_truther", 812, "next one's going to be called 'Mood.' or worse — 'Pause.' i'm bracing.", agoMin: 2880, score: 104, depth: 0, home: "LES", [rmake("orchard_walker", 987, "Pause. for real. don't manifest it.", agoMin: 2880, score: 53, depth: 1, home: "LES")]),
            rmake("broomeghost", 2901, "they all have the same chair. the wide chair. the depression chair.", agoMin: 2880, score: 88, depth: 0, home: "LES"),
            rmake("avenuec", 1022, "Hush has a $9 latte and zero customers and somehow still exists. i don't understand the economics. i'm scared.", agoMin: 2880, score: 71, depth: 0, home: "LES"),
        ],
        "scaffolding on Rivington just turned 4 years old. somebody bring a cake.": [
            rmake("forsyth", 1777, "i moved in under that scaffolding. i still live under it. i may die under it.", agoMin: 2880, score: 96, depth: 0, home: "LES"),
            rmake("clintonst", 441, "they took it down for three weeks in 2023 and i didn't recognize the block. genuine vertigo. they put it back. i'm fine now.", agoMin: 2880, score: 73, depth: 0, home: "LES", [rmake("eldridge", 309, "the block needs it. it's structural at this point. emotionally.", agoMin: 2880, score: 42, depth: 1, home: "LES")]),
        ],
        "the fancy hardware store on Bowery is selling a $48 sponge. it is a sponge. it is the same sponge i can get on Essex for $1.25. but this one is gray.": [
            rmake("twobridges", 618, "is it the gray. is the gray worth $46.75. i need to know before i make a decision.", agoMin: 4320, score: 81, depth: 0, home: "LES", [rmake("norfolkghost", 2118, "the gray is the entire pitch. they've removed color from a sponge and charged you for the absence.", agoMin: 4320, score: 67, depth: 1, home: "LES")]),
            rmake("ratking", 1209, "i went in once for a hammer. they didn't have hammers. they had ONE hammer. it was $180. it was wooden. ok i guess.", agoMin: 4320, score: 89, depth: 0, home: "LES"),
            rmake("attorney_st", 1558, "the store is a vibe. the sponge is a vibe. nothing is a sponge anymore.", agoMin: 4320, score: 44, depth: 0, home: "LES"),
        ],
        "overheard on Clinton: \"i told her, the apartment doesn't get sun, but it gets vibes.\" brother. that's the sun.": [
            rmake("broomeghost", 2901, "BROTHER. THAT'S THE SUN.", agoMin: 4320, score: 198, depth: 0, home: "LES", [rmake("forsyth", 1777, "we said it together in our heads. simultaneously. citywide.", agoMin: 4320, score: 84, depth: 1, home: "LES")]),
            rmake("ludlow_loiter", 2344, "i think she signed the lease. that's the part that haunts me.", agoMin: 4320, score: 112, depth: 0, home: "LES"),
            rmake("deli_truther", 812, "the apartment has 'character.' that's what they call it when there's no closets.", agoMin: 4320, score: 76, depth: 0, home: "LES"),
        ]
    ]
}
