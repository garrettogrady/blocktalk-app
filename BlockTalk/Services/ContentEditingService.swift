import Foundation

/// Edit and delete your own posts and replies. Every branch (silent vs marked
/// edit, hard delete vs tombstone) is decided by the SECURITY DEFINER RPCs in
/// Supabase/00024_edits_and_deletes.sql; this just calls them and reports back.
struct ContentEditingService {
    struct EditResult: Decodable {
        let success: Bool
        var error: String?
        var message: String?
        /// True when the edit was tagged (the content already had votes or replies).
        var marked: Bool?
        var text: String?
        var originalText: String?
        var editCount: Int?

        enum CodingKeys: String, CodingKey {
            case success, error, message, marked, text
            case originalText = "original_text"
            case editCount = "edit_count"
        }
    }

    enum DeleteOutcome: String, Decodable {
        /// Row is gone.
        case hard
        /// Row survives with its body blanked so the thread beneath it stands.
        case tombstone
    }

    struct DeleteResult: Decodable {
        let success: Bool
        var error: String?
        var message: String?
        var outcome: DeleteOutcome?
        var replyCount: Int?

        enum CodingKeys: String, CodingKey {
            case success, error, message, outcome
            case replyCount = "reply_count"
        }
    }

    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    func editPost(id: UUID, text: String) async throws -> EditResult {
        let result: EditResult = try await supabase.rpc(
            "edit_post",
            params: ["p_post_id": id.uuidString, "p_text": text]
        ).execute().value
        guard result.success else { throw Failure(message: result.message ?? "Couldn't save your edit.") }
        return result
    }

    func deletePost(id: UUID) async throws -> DeleteResult {
        let result: DeleteResult = try await supabase.rpc(
            "delete_post",
            params: ["p_post_id": id.uuidString]
        ).execute().value
        guard result.success else { throw Failure(message: result.message ?? "Couldn't delete this post.") }
        return result
    }

    func editReply(id: UUID, text: String) async throws -> EditResult {
        let result: EditResult = try await supabase.rpc(
            "edit_reply",
            params: ["p_reply_id": id.uuidString, "p_text": text]
        ).execute().value
        guard result.success else { throw Failure(message: result.message ?? "Couldn't save your edit.") }
        return result
    }

    func deleteReply(id: UUID) async throws -> DeleteResult {
        let result: DeleteResult = try await supabase.rpc(
            "delete_reply",
            params: ["p_reply_id": id.uuidString]
        ).execute().value
        guard result.success else { throw Failure(message: result.message ?? "Couldn't delete this reply.") }
        return result
    }
}
