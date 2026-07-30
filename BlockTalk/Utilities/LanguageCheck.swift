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

    /// Remove spaces that sit between two single-character tokens, so letter-
    /// spacing evasion ("k i k e", or "k.i.k.e" after normalize → "k i k e")
    /// collapses to "kike" — while real multi-letter words stay separated
    /// ("this pic" is left untouched, so it can't fuse into "spic").
    private static func collapseLetterSpacing(_ spaced: String) -> String {
        spaced.replacingOccurrences(of: "(?<=\\b\\w) (?=\\w\\b)", with: "", options: .regularExpression)
    }

    static func containsHateSpeech(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        let spaced = normalize(text)
        // Real word spaces preserved; only letter-spacing evasion is collapsed.
        let collapsed = collapseLetterSpacing(spaced)
        // Fully-despaced form only for compound slurs (long/specific enough that
        // run-together spelling is safe — "porchmonkey" has no innocent collision).
        let despaced = spaced.replacingOccurrences(of: " ", with: "")

        func strip(_ s: String) -> String {
            var out = s
            for safe in allowlist { out = out.replacingOccurrences(of: safe, with: " ") }
            return out
        }
        let cleanedCollapsed = strip(collapsed)
        let cleanedDespaced = strip(despaced)

        for slur in blocked {
            if slur.contains(" ") {
                // Compound: allow both spaced and run-together spellings.
                let needle = slur.replacingOccurrences(of: " ", with: "")
                if cleanedCollapsed.contains(slur) || cleanedDespaced.contains(needle) { return true }
            } else {
                // Single word: match on the space-preserving form so adjacent
                // innocent words ("this pic") can never join into a slur ("spic").
                if cleanedCollapsed.contains(slur) { return true }
            }
        }
        return false
    }
}
