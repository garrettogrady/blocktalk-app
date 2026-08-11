import Foundation

struct EnrollmentService {
    func enroll(userId: UUID, postId: UUID) async throws {
        try await supabase.from("enrollments")
            .upsert([
                "user_id": userId.uuidString,
                "post_id": postId.uuidString,
            ], onConflict: "user_id,post_id")
            .execute()
    }

    func unenroll(userId: UUID, postId: UUID) async throws {
        try await supabase.from("enrollments")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("post_id", value: postId.uuidString)
            .execute()
    }

    func enrolledPostIds(userId: UUID) async throws -> Set<UUID> {
        struct Row: Decodable { let postId: UUID
            enum CodingKeys: String, CodingKey { case postId = "post_id" }
        }
        let rows: [Row] = try await supabase.from("enrollments")
            .select("post_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return Set(rows.map(\.postId))
    }

    func enrolledPostIds(userId: UUID, among postIds: [UUID]) async throws -> Set<UUID> {
        guard !postIds.isEmpty else { return [] }
        struct Row: Decodable { let postId: UUID
            enum CodingKeys: String, CodingKey { case postId = "post_id" }
        }
        let ids = postIds.map(\.uuidString)
        let rows: [Row] = try await supabase.from("enrollments")
            .select("post_id")
            .eq("user_id", value: userId.uuidString)
            .in("post_id", values: ids)
            .execute()
            .value
        return Set(rows.map(\.postId))
    }
}
