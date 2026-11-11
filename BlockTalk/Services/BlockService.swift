import Foundation

struct BlockService {
    func block(blockerId: UUID, blockedId: UUID) async throws {
        try await supabase.from("user_blocks")
            .insert(["blocker_id": blockerId.uuidString, "blocked_id": blockedId.uuidString])
            .execute()
    }

    func unblock(blockerId: UUID, blockedId: UUID) async throws {
        try await supabase.from("user_blocks")
            .delete()
            .eq("blocker_id", value: blockerId.uuidString)
            .eq("blocked_id", value: blockedId.uuidString)
            .execute()
    }

    func fetchBlockedIds(userId: UUID) async throws -> Set<UUID> {
        struct Row: Decodable { let blocked_id: UUID }
        let rows: [Row] = try await supabase.from("user_blocks")
            .select("blocked_id")
            .eq("blocker_id", value: userId.uuidString)
            .execute()
            .value
        return Set(rows.map(\.blocked_id))
    }
}
