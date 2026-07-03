import Foundation

@Observable
final class ProfileViewModel {
    var username = "BlockTalker"
    var selectedNeighborhood: Neighborhood?
    var isSubmitting = false
    var error: String?

    private static let defaultName = "BlockTalker"

    // Hardcoded sets matching the React app exactly
    private static let takenUsernames: Set<String> = [
        "ratking", "avenuec", "deli_truther", "admin", "blocktalk"
    ]
    private static let blockedUsernames: Set<String> = [
        "mod", "official", "moderator", "staff", "support"
    ]

    enum UsernameState {
        case `default`  // matches the default "BlockTalker"
        case valid
        case taken
        case invalid    // fails regex: not 3-20 alphanumeric + underscore
        case blocked    // reserved word
        case hate       // hate speech detected
        case empty      // trimmed to nothing
    }

    /// Computed exactly like the React app's useMemo
    var usernameState: UsernameState {
        let v = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if v.isEmpty { return .empty }

        if v.caseInsensitiveCompare(Self.defaultName) == .orderedSame {
            return .default
        }

        let lower = v.lowercased()

        // Regex: 3-20 chars, letters/numbers/underscores only
        let regex = /^[a-zA-Z0-9_]{3,20}$/
        if v.wholeMatch(of: regex) == nil {
            return .invalid
        }

        if Self.blockedUsernames.contains(lower) {
            return .blocked
        }

        if Self.takenUsernames.contains(lower) {
            return .taken
        }

        if LanguageCheck.containsHateSpeech(v) {
            return .hate
        }

        return .valid
    }

    var usernameOk: Bool {
        usernameState == .default || usernameState == .valid
    }

    var canContinue: Bool {
        usernameOk && selectedNeighborhood != nil
    }
}
