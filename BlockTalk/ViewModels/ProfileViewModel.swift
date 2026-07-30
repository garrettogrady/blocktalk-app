import Foundation

@Observable
final class ProfileViewModel {
    var username = "BlockTalker"
    var selectedNeighborhood: Neighborhood?
    var isSubmitting = false
    var error: String?

    /// Whether the current username is taken (checked against Supabase)
    var isUsernameTaken = false
    /// Debounce task for username availability check
    private var checkTask: Task<Void, Never>?

    private static let defaultName = "BlockTalker"

    private static let blockedUsernames: Set<String> = [
        "mod", "official", "moderator", "staff", "support"
    ]

    enum UsernameState {
        case `default`
        case valid
        case taken
        case invalid
        case blocked
        case hate
        case empty
        case checking
    }

    var usernameState: UsernameState {
        let v = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if v.isEmpty { return .empty }

        if v.caseInsensitiveCompare(Self.defaultName) == .orderedSame {
            return .default
        }

        let lower = v.lowercased()

        let regex = /^[a-zA-Z0-9_]{3,20}$/
        if v.wholeMatch(of: regex) == nil {
            return .invalid
        }

        if Self.blockedUsernames.contains(lower) {
            return .blocked
        }

        if LanguageCheck.containsHateSpeech(v) {
            return .hate
        }

        if isUsernameTaken {
            return .taken
        }

        return .valid
    }

    var usernameOk: Bool {
        usernameState == .default || usernameState == .valid
    }

    var canContinue: Bool {
        usernameOk && selectedNeighborhood != nil
    }

    /// Debounced check of username availability against the users table.
    func checkUsernameTaken() {
        checkTask?.cancel()
        isUsernameTaken = false

        let v = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty,
              v.caseInsensitiveCompare(Self.defaultName) != .orderedSame,
              v.wholeMatch(of: /^[a-zA-Z0-9_]{3,20}$/) != nil
        else { return }

        checkTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            do {
                struct IdRow: Decodable { let id: UUID }
                // Escape LIKE wildcards — aliases are underscore-heavy and `_`/`%`
                // would otherwise match unintended rows (false "taken"/missed collision).
                let pattern = v
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "%", with: "\\%")
                    .replacingOccurrences(of: "_", with: "\\_")
                let results: [IdRow] = try await supabase.from("users")
                    .select("id")
                    .ilike("username", value: pattern)
                    .limit(1)
                    .execute()
                    .value
                if !Task.isCancelled {
                    isUsernameTaken = !results.isEmpty
                }
            } catch {
                // Network error — don't block the user
            }
        }
    }
}
