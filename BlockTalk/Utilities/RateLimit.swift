import Foundation

/// Server-side rate limits (Supabase/00026_rate_limits.sql) reject an insert
/// with an error whose message is "rate_limited: <sentence for the user>".
/// This pulls that sentence out so screens can show it instead of a generic
/// "couldn't post" message.
enum RateLimit {
    static let marker = "rate_limited: "

    /// The user-facing sentence, or nil if this isn't a rate-limit error.
    static func message(for error: Error) -> String? {
        message(in: String(describing: error)) ?? message(in: error.localizedDescription)
    }

    static func message(in text: String) -> String? {
        guard let range = text.range(of: marker) else { return nil }
        var rest = text[range.upperBound...]
        // The message is usually followed by the framework's own decoration
        // (a closing quote, "hint:", "code:"). Keep just the sentence.
        if let end = rest.firstIndex(where: { $0 == "\"" || $0 == "\n" }) {
            rest = rest[..<end]
        }
        let sentence = rest.trimmingCharacters(in: .whitespacesAndNewlines)
        return sentence.isEmpty ? nil : sentence
    }
}
