import AuthenticationServices
import Foundation
import Supabase

@Observable
final class AuthService {
    var isSigningIn = false
    var error: String?

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> Session {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8)
        else {
            throw AuthError.missingToken
        }

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )
        return session
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    func currentSession() async -> Session? {
        try? await supabase.auth.session
    }

    func createUserProfile(userId: UUID, username: String, neighborhoodId: UUID) async throws {
        // Do NOT send user_number — the column is a SERIAL sequence in the DB,
        // so it auto-assigns a unique, monotonic "Nth user" number. (Sending a
        // random client value overrode the sequence and could collide.) The
        // caller reads the row back to get the assigned number.
        try await supabase.from("users")
            .insert([
                "id": userId.uuidString,
                "username": username,
                "home_neighborhood_id": neighborhoodId.uuidString,
            ])
            .execute()
    }

    enum AuthError: LocalizedError {
        case missingToken

        var errorDescription: String? {
            switch self {
            case .missingToken: "Missing identity token from Apple Sign In"
            }
        }
    }
}
