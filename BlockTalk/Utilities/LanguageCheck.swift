import Foundation

enum LanguageCheck {
    private struct Entry {
        let word: String
        let greedy: Bool

        init(_ word: String, greedy: Bool = false) {
            self.word = word
            self.greedy = greedy
        }
    }

    private static let blocked: [Entry] = [
        // Anti-Black
        Entry("nigger", greedy: true),
        Entry("coon"), Entry("coons"),
        Entry("jigaboo"), Entry("jigaboos"),
        Entry("porch monkey"),
        Entry("jungle bunny"),
        // Anti-Jewish
        Entry("kike"), Entry("kikes"),
        // Anti-Latino
        Entry("spic"), Entry("spics"),
        Entry("wetback"), Entry("wetbacks"),
        Entry("beaner"), Entry("beaners"),
        // Anti-Asian
        Entry("chink"), Entry("chinks"),
        Entry("gook"), Entry("gooks"),
        Entry("zipperhead"), Entry("zipperheads"),
        // Anti-Arab/Muslim
        Entry("raghead"), Entry("ragheads"),
        Entry("towelhead"), Entry("towelheads"),
        Entry("camel jockey"),
        // Anti-Romani
        Entry("pikey"), Entry("pikeys"),
        // Anti-Native American
        Entry("injun"), Entry("injuns"),
        // Anti-LGBTQ+
        Entry("fag"), Entry("fags"),
        Entry("faggot", greedy: true),
        Entry("carpet muncher"),
        Entry("rug muncher"),
        Entry("pillow biter"),
        // Anti-trans
        Entry("tranny"), Entry("trannies"), Entry("trannys"), Entry("trannie"),
        Entry("shemale"), Entry("shemales"),
        // Ableist
        Entry("mongoloid"), Entry("mongoloids"),
    ]

    private static let singleWordRegexes: [NSRegularExpression] = {
        blocked
            .filter { !$0.word.contains(" ") }
            .compactMap { entry in
                let pattern = entry.greedy
                    ? "\\b\(NSRegularExpression.escapedPattern(for: entry.word))\\w*\\b"
                    : "\\b\(NSRegularExpression.escapedPattern(for: entry.word))\\b"
                return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            }
    }()

    private static let compoundPhrases: [String] = {
        blocked
            .filter { $0.word.contains(" ") }
            .map { $0.word }
    }()

    private static func normalize(_ text: String) -> String {
        var result = text.lowercased()
        result = result.replacingOccurrences(of: "[1!|]", with: "i", options: .regularExpression)
        result = result.replacingOccurrences(of: "3", with: "e")
        result = result.replacingOccurrences(of: "@", with: "a")
        result = result.replacingOccurrences(of: "0", with: "o")
        result = result.replacingOccurrences(of: "[\\W_]+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }

    static func containsHateSpeech(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let normalized = normalize(text)
        let range = NSRange(normalized.startIndex..., in: normalized)

        for regex in singleWordRegexes {
            if regex.firstMatch(in: normalized, range: range) != nil {
                return true
            }
        }

        for phrase in compoundPhrases {
            if normalized.contains(phrase) { return true }
            if normalized.contains(phrase.replacingOccurrences(of: " ", with: "")) { return true }
        }

        return false
    }
}
