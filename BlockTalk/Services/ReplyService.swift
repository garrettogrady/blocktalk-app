import Foundation

struct ReplyService {
    static let replySelect = "*, author:users!replies_user_id_fkey(username, user_number, home:neighborhoods(short_code))"

    func fetchReplies(postId: UUID) async throws -> [Reply] {
        let flat: [Reply] = try await supabase.from("replies")
            .select(ReplyService.replySelect)
            .eq("post_id", value: postId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        return buildTree(from: flat)
    }

    func createReply(postId: UUID, userId: UUID, text: String, parentReplyId: UUID? = nil, depth: Int = 0) async throws -> Reply {
        var data: [String: String] = [
            "post_id": postId.uuidString,
            "user_id": userId.uuidString,
            "text": text,
            "depth": "\(depth)",
        ]
        if let parentReplyId {
            data["parent_reply_id"] = parentReplyId.uuidString
        }

        return try await supabase.from("replies")
            .insert(data)
            .select(ReplyService.replySelect)
            .single()
            .execute()
            .value
    }

    func vote(replyId: UUID, userId: UUID, direction: Int) async throws {
        try await supabase.from("votes")
            .upsert([
                "user_id": userId.uuidString,
                "reply_id": replyId.uuidString,
                "direction": "\(direction)",
            ], onConflict: "user_id,reply_id")
            .execute()
    }

    func buildTree(from flat: [Reply]) -> [Reply] {
        var lookup: [UUID: Reply] = [:]
        var roots: [Reply] = []

        for var reply in flat {
            reply.children = []
            lookup[reply.id] = reply
        }

        for reply in flat {
            if let parentId = reply.parentReplyId, var parent = lookup[parentId] {
                parent.children?.append(lookup[reply.id]!)
                lookup[parentId] = parent
            } else {
                roots.append(lookup[reply.id]!)
            }
        }

        // Rebuild with nested children
        func resolve(_ id: UUID) -> Reply {
            var r = lookup[id]!
            r.children = r.children?.map { resolve($0.id) }
            return r
        }

        return roots.map { resolve($0.id) }
    }
}
