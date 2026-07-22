import Foundation

enum LanguageCheck {
    // Sanctioned slurs. Detection is substring-based (after normalizing) so a
    // slur is caught even when embedded in a larger handle, e.g. "kikekiller".
    private static let blocked: [String] = [
        // Anti-Black
        "nigger", "coon", "jigaboo", "porch monkey", "jungle bunny",
        // Anti-Jewish
        "kike",
        // Anti-Latino
        "spic", "wetback", "beaner",
        // Anti-Asian
        "chink", "gook", "zipperhead",
        // Anti-Arab/Muslim
        "raghead", "towelhead", "camel jockey",
        // Anti-Romani
        "pikey",
        // Anti-Native American
        "injun",
        // Anti-LGBTQ+
        "fag", "faggot", "carpet muncher", "rug muncher", "pillow biter",
        // Anti-trans
        "tranny", "trannie", "shemale",
        // Ableist
        "mongoloid",
    ]

    // Benign words that merely CONTAIN a slur as a substring. Stripped before
    // detection so we don't false-positive them (the "Scunthorpe problem"):
    // e.g. raccoon/spice/despicable/Fagan should all pass.
    private static let allowlist: [String] = [
        "raccoon", "racoon", "cocoon", "tycoon",
        "spice", "spicy", "spices", "spicier", "spiciest",
        "despicable", "conspicuous", "inconspicuous",
        "suspicious", "suspicion", "auspicious", "perspicacious",
        "gobbledygook",
        "fagan", "fagin", "fagundes", "fagund", "fage",
    ]

    /// Lowercase, undo common leetspeak, and reduce anything non-alphanumeric to
    /// a single space (so "k1ke", "k.i.k.e", "kike_killer" all normalize).
    private static func normalize(_ text: String) -> String {
        var result = text.lowercased()
        result = result.replacingOccurrences(of: "[1!|]", with: "i", options: .regularExpression)
        result = result.replacingOccurrences(of: "3", with: "e")
        result = result.replacingOccurrences(of: "@", with: "a")
        result = result.replacingOccurrences(of: "0", with: "o")
        result = result.replacingOccurrences(of: "5", with: "s")
        result = result.replacingOccurrences(of: "[\\W_]+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }

    static func containsHateSpeech(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        // Two views: the spaced form (words separated) and the despaced form so
        // separator-evasion ("k i k e", "kike.killer") collapses to "kikekiller".
        let spaced = normalize(text)
        let despaced = spaced.replacingOccurrences(of: " ", with: "")

        // Remove benign words first, replacing with a break so we can't create a
        // new slur by joining leftovers.
        var cleaned = despaced
        for safe in allowlist {
            cleaned = cleaned.replacingOccurrences(of: safe, with: " ")
        }

        for slur in blocked {
            let needle = slur.replacingOccurrences(of: " ", with: "")
            if cleaned.contains(needle) { return true }
        }
        return false
    }
}
