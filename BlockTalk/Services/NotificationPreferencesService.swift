import Foundation

struct NotificationPreferencesService {
    func fetch(userId: UUID) async throws -> NotificationPreferences? {
        let rows: [NotificationPreferences] = try await supabase.from("notification_preferences")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func upsert(_ prefs: NotificationPreferences) async throws {
        try await supabase.from("notification_preferences")
            .upsert(prefs, onConflict: "user_id")
            .execute()
    }
}
