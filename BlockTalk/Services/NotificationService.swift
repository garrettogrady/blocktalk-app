import Foundation

struct NotificationService {
    func fetch(userId: UUID, limit: Int = 50) async throws -> [BTNotification] {
        try await supabase.from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func markAllRead(userId: UUID) async throws {
        try await supabase.from("notifications")
            .update(["unread": false])
            .eq("user_id", value: userId.uuidString)
            .eq("unread", value: true)
            .execute()
    }

    func markRead(id: UUID) async throws {
        try await supabase.from("notifications")
            .update(["unread": false])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func unreadCount(userId: UUID) async throws -> Int {
        let result: [BTNotification] = try await supabase.from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("unread", value: true)
            .execute()
            .value
        return result.count
    }
}
