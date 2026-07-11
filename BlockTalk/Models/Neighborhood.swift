import Foundation

enum Borough: String, Codable, CaseIterable, Sendable {
    case manhattan = "Manhattan"
    case brooklyn = "Brooklyn"
    case queens = "Queens"
    case bronx = "Bronx"
    case statenIsland = "Staten Island"
}

struct Neighborhood: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let shortCode: String
    let borough: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case shortCode = "short_code"
        case borough
    }

    /// Local LES neighborhood for the bundled mock (id shared with sample posts)
    static let les = Neighborhood(
        id: Post.lesNeighborhoodId,
        name: "Lower East Side",
        shortCode: "LES",
        borough: "Manhattan"
    )

    /// A few neighborhoods for the Discover "Random Neighborhoods" list
    static let sampleRandom: [Neighborhood] = [
        Neighborhood(id: UUID(), name: "Williamsburg", shortCode: "WILLYB", borough: "Brooklyn"),
        Neighborhood(id: UUID(), name: "Astoria", shortCode: "ASTORIA", borough: "Queens"),
        Neighborhood(id: UUID(), name: "SoHo", shortCode: "SOHO", borough: "Manhattan"),
        Neighborhood(id: UUID(), name: "Fordham Heights", shortCode: "FH", borough: "Bronx"),
        Neighborhood(id: UUID(), name: "Park Slope", shortCode: "SLOPE", borough: "Brooklyn"),
    ]
}

enum NeighborhoodDirectory {
    struct Entry {
        let name: String
        let shortCode: String
        let borough: String
    }

    static let all: [Entry] = [
        // Manhattan
        Entry(name: "Chelsea", shortCode: "CHELSEA", borough: "Manhattan"),
        Entry(name: "Chinatown", shortCode: "C-TOWN", borough: "Manhattan"),
        Entry(name: "East Harlem", shortCode: "E.HARLEM", borough: "Manhattan"),
        Entry(name: "East Midtown", shortCode: "E.MID", borough: "Manhattan"),
        Entry(name: "East Village", shortCode: "EV", borough: "Manhattan"),
        Entry(name: "Financial District", shortCode: "FIDI", borough: "Manhattan"),
        Entry(name: "Flatiron", shortCode: "FLATIRON", borough: "Manhattan"),
        Entry(name: "Gramercy", shortCode: "GRAMERCY", borough: "Manhattan"),
        Entry(name: "Greenwich Village", shortCode: "GV", borough: "Manhattan"),
        Entry(name: "Hamilton Heights", shortCode: "HAM.HTS", borough: "Manhattan"),
        Entry(name: "Harlem", shortCode: "HARLEM", borough: "Manhattan"),
        Entry(name: "Hell's Kitchen", shortCode: "HK", borough: "Manhattan"),
        Entry(name: "Inwood", shortCode: "INWOOD", borough: "Manhattan"),
        Entry(name: "Lower East Side", shortCode: "LES", borough: "Manhattan"),
        Entry(name: "Manhattanville", shortCode: "M.VILLE", borough: "Manhattan"),
        Entry(name: "Midtown", shortCode: "MIDTOWN", borough: "Manhattan"),
        Entry(name: "Morningside Heights", shortCode: "MORNING", borough: "Manhattan"),
        Entry(name: "Murray Hill", shortCode: "MURRAY", borough: "Manhattan"),
        Entry(name: "SoHo", shortCode: "SOHO", borough: "Manhattan"),
        Entry(name: "Stuyvesant Town", shortCode: "STUY.TOWN", borough: "Manhattan"),
        Entry(name: "Tribeca", shortCode: "TRIBECA", borough: "Manhattan"),
        Entry(name: "Upper East Side", shortCode: "UES", borough: "Manhattan"),
        Entry(name: "Upper West Side", shortCode: "UWS", borough: "Manhattan"),
        Entry(name: "Washington Heights", shortCode: "WASH.HTS", borough: "Manhattan"),
        Entry(name: "West Village", shortCode: "WV", borough: "Manhattan"),

        // Brooklyn
        Entry(name: "Bath Beach", shortCode: "BB", borough: "Brooklyn"),
        Entry(name: "Bay Ridge", shortCode: "BR", borough: "Brooklyn"),
        Entry(name: "Bedford", shortCode: "BEDFORD", borough: "Brooklyn"),
        Entry(name: "Bensonhurst", shortCode: "BENSONHURST", borough: "Brooklyn"),
        Entry(name: "Borough Park", shortCode: "BP", borough: "Brooklyn"),
        Entry(name: "Brighton Beach", shortCode: "BB", borough: "Brooklyn"),
        Entry(name: "Brooklyn Heights", shortCode: "BH", borough: "Brooklyn"),
        Entry(name: "Brownsville", shortCode: "BROWNSVILLE", borough: "Brooklyn"),
        Entry(name: "Bushwick", shortCode: "BUSHWICK", borough: "Brooklyn"),
        Entry(name: "Canarsie", shortCode: "CANARSIE", borough: "Brooklyn"),
        Entry(name: "Carroll Gardens", shortCode: "CG", borough: "Brooklyn"),
        Entry(name: "Clinton Hill", shortCode: "CH", borough: "Brooklyn"),
        Entry(name: "Coney Island", shortCode: "CI", borough: "Brooklyn"),
        Entry(name: "Crown Heights", shortCode: "CH", borough: "Brooklyn"),
        Entry(name: "Cypress Hills", shortCode: "CH", borough: "Brooklyn"),
        Entry(name: "Downtown Brooklyn", shortCode: "DB", borough: "Brooklyn"),
        Entry(name: "Dyker Heights", shortCode: "DH", borough: "Brooklyn"),
        Entry(name: "East Flatbush", shortCode: "EF", borough: "Brooklyn"),
        Entry(name: "East New York", shortCode: "ENY", borough: "Brooklyn"),
        Entry(name: "East Williamsburg", shortCode: "EW", borough: "Brooklyn"),
        Entry(name: "Flatbush", shortCode: "FLATBUSH", borough: "Brooklyn"),
        Entry(name: "Flatlands", shortCode: "FLATLANDS", borough: "Brooklyn"),
        Entry(name: "Fort Greene", shortCode: "FG", borough: "Brooklyn"),
        Entry(name: "Gravesend", shortCode: "GRAVESEND", borough: "Brooklyn"),
        Entry(name: "Greenpoint", shortCode: "GPOINT", borough: "Brooklyn"),
        Entry(name: "Kensington", shortCode: "KENSINGTON", borough: "Brooklyn"),
        Entry(name: "Madison", shortCode: "MADISON", borough: "Brooklyn"),
        Entry(name: "Mapleton", shortCode: "MAPLETON", borough: "Brooklyn"),
        Entry(name: "Marine Park", shortCode: "MP", borough: "Brooklyn"),
        Entry(name: "Midwood", shortCode: "MIDWOOD", borough: "Brooklyn"),
        Entry(name: "Ocean Hill", shortCode: "OH", borough: "Brooklyn"),
        Entry(name: "Park Slope", shortCode: "SLOPE", borough: "Brooklyn"),
        Entry(name: "Prospect Heights", shortCode: "PH", borough: "Brooklyn"),
        Entry(name: "Prospect Lefferts Gardens", shortCode: "PLG", borough: "Brooklyn"),
        Entry(name: "Sheepshead Bay", shortCode: "SB", borough: "Brooklyn"),
        Entry(name: "South Williamsburg", shortCode: "SW", borough: "Brooklyn"),
        Entry(name: "Spring Creek", shortCode: "SC", borough: "Brooklyn"),
        Entry(name: "Sunset Park", shortCode: "SP", borough: "Brooklyn"),
        Entry(name: "Williamsburg", shortCode: "WILLYB", borough: "Brooklyn"),
        Entry(name: "Windsor Terrace", shortCode: "WT", borough: "Brooklyn"),

        // Queens
        Entry(name: "Astoria", shortCode: "ASTORIA", borough: "Queens"),
        Entry(name: "Auburndale", shortCode: "AUBURNDALE", borough: "Queens"),
        Entry(name: "Baisley Park", shortCode: "BP", borough: "Queens"),
        Entry(name: "Bay Terrace", shortCode: "BT", borough: "Queens"),
        Entry(name: "Bayside", shortCode: "BAYSIDE", borough: "Queens"),
        Entry(name: "Bellerose", shortCode: "BELLEROSE", borough: "Queens"),
        Entry(name: "Breezy Point", shortCode: "BP", borough: "Queens"),
        Entry(name: "Cambria Heights", shortCode: "CH", borough: "Queens"),
        Entry(name: "College Point", shortCode: "CP", borough: "Queens"),
        Entry(name: "Corona", shortCode: "CORONA", borough: "Queens"),
        Entry(name: "Douglaston", shortCode: "DOUGLASTON", borough: "Queens"),
        Entry(name: "East Elmhurst", shortCode: "EE", borough: "Queens"),
        Entry(name: "East Flushing", shortCode: "EF", borough: "Queens"),
        Entry(name: "Elmhurst", shortCode: "ELMHURST", borough: "Queens"),
        Entry(name: "Far Rockaway", shortCode: "FR", borough: "Queens"),
        Entry(name: "Flushing", shortCode: "FLUSHING", borough: "Queens"),
        Entry(name: "Forest Hills", shortCode: "FH", borough: "Queens"),
        Entry(name: "Fresh Meadows", shortCode: "FM", borough: "Queens"),
        Entry(name: "Glen Oaks", shortCode: "GO", borough: "Queens"),
        Entry(name: "Glendale", shortCode: "GLENDALE", borough: "Queens"),
        Entry(name: "Hollis", shortCode: "HOLLIS", borough: "Queens"),
        Entry(name: "Howard Beach", shortCode: "HB", borough: "Queens"),
        Entry(name: "Jackson Heights", shortCode: "JH", borough: "Queens"),
        Entry(name: "Jamaica", shortCode: "JAMAICA", borough: "Queens"),
        Entry(name: "Jamaica Estates", shortCode: "JE", borough: "Queens"),
        Entry(name: "Jamaica Hills", shortCode: "JH", borough: "Queens"),
        Entry(name: "Kew Gardens", shortCode: "KG", borough: "Queens"),
        Entry(name: "Kew Gardens Hills", shortCode: "KGH", borough: "Queens"),
        Entry(name: "Laurelton", shortCode: "LAURELTON", borough: "Queens"),
        Entry(name: "Long Island City", shortCode: "LIC", borough: "Queens"),
        Entry(name: "Maspeth", shortCode: "MASPETH", borough: "Queens"),
        Entry(name: "Middle Village", shortCode: "MV", borough: "Queens"),
        Entry(name: "Murray Hill (Queens)", shortCode: "MURRAY", borough: "Queens"),
        Entry(name: "North Corona", shortCode: "NC", borough: "Queens"),
        Entry(name: "Oakland Gardens", shortCode: "OG", borough: "Queens"),
        Entry(name: "Old Astoria", shortCode: "OA", borough: "Queens"),
        Entry(name: "Ozone Park", shortCode: "OP", borough: "Queens"),
        Entry(name: "Pomonok", shortCode: "POMONOK", borough: "Queens"),
        Entry(name: "Queens Village", shortCode: "QV", borough: "Queens"),
        Entry(name: "Queensboro Hill", shortCode: "QH", borough: "Queens"),
        Entry(name: "Queensbridge", shortCode: "QUEENSBRIDGE", borough: "Queens"),
        Entry(name: "Rego Park", shortCode: "RP", borough: "Queens"),
        Entry(name: "Richmond Hill", shortCode: "RH", borough: "Queens"),
        Entry(name: "Ridgewood", shortCode: "RIDGEWOOD", borough: "Queens"),
        Entry(name: "Rockaway Beach", shortCode: "RB", borough: "Queens"),
        Entry(name: "Rosedale", shortCode: "ROSEDALE", borough: "Queens"),
        Entry(name: "South Jamaica", shortCode: "SJ", borough: "Queens"),
        Entry(name: "South Ozone Park", shortCode: "SOP", borough: "Queens"),
        Entry(name: "South Richmond Hill", shortCode: "SRH", borough: "Queens"),
        Entry(name: "Springfield Gardens", shortCode: "SG", borough: "Queens"),
        Entry(name: "St. Albans", shortCode: "SA", borough: "Queens"),
        Entry(name: "Sunnyside", shortCode: "SUNNYSIDE", borough: "Queens"),
        Entry(name: "Whitestone", shortCode: "WHITESTONE", borough: "Queens"),
        Entry(name: "Woodhaven", shortCode: "WOODHAVEN", borough: "Queens"),
        Entry(name: "Woodside", shortCode: "WOODSIDE", borough: "Queens"),

        // Bronx
        Entry(name: "Allerton", shortCode: "ALLERTON", borough: "Bronx"),
        Entry(name: "Bedford Park", shortCode: "BP", borough: "Bronx"),
        Entry(name: "Belmont", shortCode: "BELMONT", borough: "Bronx"),
        Entry(name: "Castle Hill", shortCode: "CH", borough: "Bronx"),
        Entry(name: "Claremont Village", shortCode: "CV", borough: "Bronx"),
        Entry(name: "Co-op City", shortCode: "COC", borough: "Bronx"),
        Entry(name: "Concourse", shortCode: "CONCOURSE", borough: "Bronx"),
        Entry(name: "Crotona Park East", shortCode: "CPE", borough: "Bronx"),
        Entry(name: "Eastchester", shortCode: "EASTCHESTER", borough: "Bronx"),
        Entry(name: "Fordham Heights", shortCode: "FH", borough: "Bronx"),
        Entry(name: "Highbridge", shortCode: "HIGHBRIDGE", borough: "Bronx"),
        Entry(name: "Hunts Point", shortCode: "HP", borough: "Bronx"),
        Entry(name: "Kingsbridge", shortCode: "KINGSBRIDGE", borough: "Bronx"),
        Entry(name: "Kingsbridge Heights", shortCode: "KH", borough: "Bronx"),
        Entry(name: "Longwood", shortCode: "LONGWOOD", borough: "Bronx"),
        Entry(name: "Melrose", shortCode: "MELROSE", borough: "Bronx"),
        Entry(name: "Morris Park", shortCode: "MP", borough: "Bronx"),
        Entry(name: "Morrisania", shortCode: "MORRISANIA", borough: "Bronx"),
        Entry(name: "Mott Haven", shortCode: "MH", borough: "Bronx"),
        Entry(name: "Mount Eden", shortCode: "ME", borough: "Bronx"),
        Entry(name: "Mount Hope", shortCode: "MH", borough: "Bronx"),
        Entry(name: "Norwood", shortCode: "NORWOOD", borough: "Bronx"),
        Entry(name: "Parkchester", shortCode: "PARKCHESTER", borough: "Bronx"),
        Entry(name: "Pelham Bay", shortCode: "PB", borough: "Bronx"),
        Entry(name: "Pelham Gardens", shortCode: "PG", borough: "Bronx"),
        Entry(name: "Pelham Parkway", shortCode: "PP", borough: "Bronx"),
        Entry(name: "Riverdale", shortCode: "RIVERDALE", borough: "Bronx"),
        Entry(name: "Soundview", shortCode: "SOUNDVIEW", borough: "Bronx"),
        Entry(name: "Throgs Neck", shortCode: "TN", borough: "Bronx"),
        Entry(name: "Tremont", shortCode: "TREMONT", borough: "Bronx"),
        Entry(name: "University Heights", shortCode: "UH", borough: "Bronx"),
        Entry(name: "Wakefield", shortCode: "WAKEFIELD", borough: "Bronx"),
        Entry(name: "West Farms", shortCode: "WF", borough: "Bronx"),
        Entry(name: "Westchester Square", shortCode: "WS", borough: "Bronx"),
        Entry(name: "Williamsbridge", shortCode: "WILLIAMSBRIDGE", borough: "Bronx"),

        // Staten Island
        Entry(name: "Annadale", shortCode: "ANNADALE", borough: "Staten Island"),
        Entry(name: "Arden Heights", shortCode: "AH", borough: "Staten Island"),
        Entry(name: "Grasmere", shortCode: "GRASMERE", borough: "Staten Island"),
        Entry(name: "Great Kills", shortCode: "GK", borough: "Staten Island"),
        Entry(name: "Mariner's Harbor", shortCode: "MH", borough: "Staten Island"),
        Entry(name: "New Dorp", shortCode: "ND", borough: "Staten Island"),
        Entry(name: "New Springville", shortCode: "NS", borough: "Staten Island"),
        Entry(name: "Oakwood", shortCode: "OAKWOOD", borough: "Staten Island"),
        Entry(name: "Port Richmond", shortCode: "PR", borough: "Staten Island"),
        Entry(name: "Rosebank", shortCode: "ROSEBANK", borough: "Staten Island"),
        Entry(name: "St. George", shortCode: "SG", borough: "Staten Island"),
        Entry(name: "Todt Hill", shortCode: "TH", borough: "Staten Island"),
        Entry(name: "Tompkinsville", shortCode: "TOMPKINSVILLE", borough: "Staten Island"),
        Entry(name: "Tottenville", shortCode: "TOTTENVILLE", borough: "Staten Island"),
        Entry(name: "West New Brighton", shortCode: "WNB", borough: "Staten Island"),
        Entry(name: "Westerleigh", shortCode: "WESTERLEIGH", borough: "Staten Island"),
    ]

    static func name(forShortCode code: String) -> String? {
        all.first { $0.shortCode == code }?.name
    }

    static func shortCode(forName name: String) -> String? {
        all.first { $0.name == name }?.shortCode
    }

    static func grouped() -> [(borough: String, entries: [Entry])] {
        let boroughs = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
        return boroughs.map { borough in
            (borough: borough, entries: all.filter { $0.borough == borough })
        }
    }
}
