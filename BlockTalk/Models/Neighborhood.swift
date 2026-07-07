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
        Neighborhood(id: UUID(), name: "Fordham", shortCode: "FORDHAM", borough: "Bronx"),
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
        Entry(name: "Battery Park City", shortCode: "BPC", borough: "Manhattan"),
        Entry(name: "Chelsea", shortCode: "CHELSEA", borough: "Manhattan"),
        Entry(name: "Chinatown", shortCode: "C-TOWN", borough: "Manhattan"),
        Entry(name: "East Harlem", shortCode: "E.HARLEM", borough: "Manhattan"),
        Entry(name: "East Village", shortCode: "EV", borough: "Manhattan"),
        Entry(name: "Financial District", shortCode: "FIDI", borough: "Manhattan"),
        Entry(name: "Flatiron", shortCode: "FLATIRON", borough: "Manhattan"),
        Entry(name: "Greenwich Village", shortCode: "GVL", borough: "Manhattan"),
        Entry(name: "Hamilton Heights", shortCode: "HAM.HTS", borough: "Manhattan"),
        Entry(name: "Harlem", shortCode: "HARLEM", borough: "Manhattan"),
        Entry(name: "Hell's Kitchen", shortCode: "HK", borough: "Manhattan"),
        Entry(name: "Inwood", shortCode: "INWOOD", borough: "Manhattan"),
        Entry(name: "Kips Bay", shortCode: "KIPS", borough: "Manhattan"),
        Entry(name: "Lower East Side", shortCode: "LES", borough: "Manhattan"),
        Entry(name: "Midtown", shortCode: "MIDTOWN", borough: "Manhattan"),
        Entry(name: "Morningside Heights", shortCode: "MS.HTS", borough: "Manhattan"),
        Entry(name: "Murray Hill", shortCode: "MURRAY", borough: "Manhattan"),
        Entry(name: "NoHo", shortCode: "NOHO", borough: "Manhattan"),
        Entry(name: "NoLita", shortCode: "NOLITA", borough: "Manhattan"),
        Entry(name: "SoHo", shortCode: "SOHO", borough: "Manhattan"),
        Entry(name: "Tribeca", shortCode: "TRIBECA", borough: "Manhattan"),
        Entry(name: "Two Bridges", shortCode: "TWO.BR", borough: "Manhattan"),
        Entry(name: "Upper East Side", shortCode: "UES", borough: "Manhattan"),
        Entry(name: "Upper West Side", shortCode: "UWS", borough: "Manhattan"),
        Entry(name: "Washington Heights", shortCode: "WASH.HTS", borough: "Manhattan"),
        Entry(name: "West Village", shortCode: "WV", borough: "Manhattan"),
        Entry(name: "Yorkville", shortCode: "YVL", borough: "Manhattan"),
        // Brooklyn
        Entry(name: "Bay Ridge", shortCode: "BAY.RIDGE", borough: "Brooklyn"),
        Entry(name: "Bedford-Stuyvesant", shortCode: "BED-STUY", borough: "Brooklyn"),
        Entry(name: "Boerum Hill", shortCode: "BOERUM", borough: "Brooklyn"),
        Entry(name: "Brooklyn Heights", shortCode: "BK.HTS", borough: "Brooklyn"),
        Entry(name: "Bushwick", shortCode: "BUSHWICK", borough: "Brooklyn"),
        Entry(name: "Carroll Gardens", shortCode: "CARROLL", borough: "Brooklyn"),
        Entry(name: "Clinton Hill", shortCode: "CLINTON", borough: "Brooklyn"),
        Entry(name: "Cobble Hill", shortCode: "COBBLE", borough: "Brooklyn"),
        Entry(name: "Coney Island", shortCode: "CONEY", borough: "Brooklyn"),
        Entry(name: "Crown Heights", shortCode: "CRN.HTS", borough: "Brooklyn"),
        Entry(name: "DUMBO", shortCode: "DUMBO", borough: "Brooklyn"),
        Entry(name: "East New York", shortCode: "ENY", borough: "Brooklyn"),
        Entry(name: "Flatbush", shortCode: "FLATBUSH", borough: "Brooklyn"),
        Entry(name: "Fort Greene", shortCode: "FT.GREENE", borough: "Brooklyn"),
        Entry(name: "Gowanus", shortCode: "GOWANUS", borough: "Brooklyn"),
        Entry(name: "Greenpoint", shortCode: "GPOINT", borough: "Brooklyn"),
        Entry(name: "Park Slope", shortCode: "SLOPE", borough: "Brooklyn"),
        Entry(name: "Prospect Heights", shortCode: "PRO.HTS", borough: "Brooklyn"),
        Entry(name: "Red Hook", shortCode: "RED HOOK", borough: "Brooklyn"),
        Entry(name: "Sunset Park", shortCode: "SUNSET", borough: "Brooklyn"),
        Entry(name: "Williamsburg", shortCode: "WILLYB", borough: "Brooklyn"),
        Entry(name: "Windsor Terrace", shortCode: "WINDSOR", borough: "Brooklyn"),
        // Queens
        Entry(name: "Astoria", shortCode: "ASTORIA", borough: "Queens"),
        Entry(name: "Bayside", shortCode: "BAYSIDE", borough: "Queens"),
        Entry(name: "Corona", shortCode: "CORONA", borough: "Queens"),
        Entry(name: "Elmhurst", shortCode: "ELMHURST", borough: "Queens"),
        Entry(name: "Far Rockaway", shortCode: "FAR.ROCK", borough: "Queens"),
        Entry(name: "Flushing", shortCode: "FLUSHING", borough: "Queens"),
        Entry(name: "Forest Hills", shortCode: "F.HILLS", borough: "Queens"),
        Entry(name: "Jackson Heights", shortCode: "JKSN.HTS", borough: "Queens"),
        Entry(name: "Jamaica", shortCode: "JAMAICA", borough: "Queens"),
        Entry(name: "Long Island City", shortCode: "LIC", borough: "Queens"),
        Entry(name: "Maspeth", shortCode: "MASPETH", borough: "Queens"),
        Entry(name: "Rego Park", shortCode: "REGO", borough: "Queens"),
        Entry(name: "Ridgewood", shortCode: "RIDGE", borough: "Queens"),
        Entry(name: "Sunnyside", shortCode: "SUNNY", borough: "Queens"),
        Entry(name: "Woodside", shortCode: "WOODSIDE", borough: "Queens"),
        // Bronx
        Entry(name: "Bedford Park", shortCode: "BED.PK", borough: "Bronx"),
        Entry(name: "Belmont", shortCode: "BELMONT", borough: "Bronx"),
        Entry(name: "Castle Hill", shortCode: "CASTLE", borough: "Bronx"),
        Entry(name: "Concourse", shortCode: "CONCOURSE", borough: "Bronx"),
        Entry(name: "Fordham", shortCode: "FORDHAM", borough: "Bronx"),
        Entry(name: "Hunts Point", shortCode: "HUNTS.PT", borough: "Bronx"),
        Entry(name: "Kingsbridge", shortCode: "K.BRIDGE", borough: "Bronx"),
        Entry(name: "Mott Haven", shortCode: "M.HAVEN", borough: "Bronx"),
        Entry(name: "Pelham Bay", shortCode: "PELHAM", borough: "Bronx"),
        Entry(name: "Riverdale", shortCode: "RIVERDALE", borough: "Bronx"),
        Entry(name: "South Bronx", shortCode: "S.BRONX", borough: "Bronx"),
        Entry(name: "Throgs Neck", shortCode: "THROGS", borough: "Bronx"),
        // Staten Island
        Entry(name: "New Brighton", shortCode: "N.BRIGHTON", borough: "Staten Island"),
        Entry(name: "Port Richmond", shortCode: "P.RICH", borough: "Staten Island"),
        Entry(name: "St. George", shortCode: "ST.GEORGE", borough: "Staten Island"),
        Entry(name: "Stapleton", shortCode: "STAPLETON", borough: "Staten Island"),
        Entry(name: "Tottenville", shortCode: "TOTTEN", borough: "Staten Island"),
        Entry(name: "West Brighton", shortCode: "W.BRIGHTON", borough: "Staten Island"),
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
