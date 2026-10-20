import Foundation
import Supabase

/// Server-side rate limits (Supabase/00026_rate_limits.sql) reject an insert
/// with a Postgres error whose message is "rate_limited: <sentence>". This
/// pulls the sentence out so screens can show it instead of a generic failure.
enum RateLimit {
    static let marker = "rate_limited: "

    /// The user-facing sentence, or nil if this isn't a rate-limit error.
    static func message(for error: Error) -> String? {
        if let pg = error as? PostgrestError {
            return message(in: pg.message)
        }
        return message(in: String(describing: error)) ?? message(in: error.localizedDescription)
    }

    static func message(in text: String) -> String? {
        guard let range = text.range(of: marker) else { return nil }
        var rest = text[range.upperBound...]
        // When parsing a printed description, stop at the framework's decoration.
        if let end = rest.firstIndex(where: { $0 == "\"" || $0 == "\n" }) {
            rest = rest[..<end]
        }
        let sentence = rest.trimmingCharacters(in: .whitespacesAndNewlines)
        return sentence.isEmpty ? nil : sentence
    }
}

/// Plain-English refusals raised by our own SQL functions (SQLSTATE P0001,
/// RAISE EXCEPTION). The message is already written for the user, so pass it
/// through as-is. Anything else (transport, auth, schema) returns nil so the
/// caller can show its generic copy.
enum ServerMessage {
    static func text(for error: Error) -> String? {
        guard let pg = error as? PostgrestError, pg.code == "P0001" else { return nil }
        let s = pg.message.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty || s.hasPrefix(RateLimit.marker) ? nil : s
    }
}
