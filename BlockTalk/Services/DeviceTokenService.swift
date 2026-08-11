import Foundation

struct DeviceTokenService {
    func register(userId: UUID, token: String, sandbox: Bool) async throws {
        try await supabase.from("device_tokens")
            .upsert([
                "user_id": userId.uuidString,
                "token": token,
                "platform": "ios",
                "sandbox": sandbox ? "true" : "false",
            ], onConflict: "user_id,token")
            .execute()
    }

    func remove(userId: UUID, token: String) async throws {
        try await supabase.from("device_tokens")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("token", value: token)
            .execute()
    }
}
