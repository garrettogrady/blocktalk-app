import Foundation

@Observable
final class PostDetailViewModel {
    var post: Post?
    var replies: [Reply] = []
    var isLoading = false
    var error: String?
    var replyText = ""
    var replyingTo: (id: UUID, username: String)?

    var replyHasHate: Bool {
        !replyText.isEmpty && LanguageCheck.containsHateSpeech(replyText)
    }

    func loadPost(id: UUID) async {
        isLoading = true
        // Post is typically passed in from the feed
        isLoading = false
    }

    private let replyService = ReplyService()

    func loadReplies(for post: Post) async {
        isLoading = true
        do {
            replies = try await replyService.fetchReplies(postId: post.id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// Create a reply via Supabase, then optimistically insert it into the
    /// local reply tree so it appears immediately.
    func sendReply(post: Post, userId: UUID, author: ReplyAuthor) {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !LanguageCheck.containsHateSpeech(trimmed) else { return }

        let parentId = replyingTo?.id
        let depth: Int = {
            guard let parentId else { return 0 }
            func findDepth(in nodes: [Reply]) -> Int? {
                for node in nodes {
                    if node.id == parentId { return min(node.depth + 1, Reply.maxDepth) }
                    if let kids = node.children, let d = findDepth(in: kids) { return d }
                }
                return nil
            }
            return findDepth(in: replies) ?? 0
        }()

        // Optimistic UI: insert immediately
        let optimistic = Reply(
            id: UUID(), postId: post.id, parentReplyId: parentId, userId: userId,
            text: trimmed, score: 0, upvoteCount: 0, downvoteCount: 0, depth: depth, createdAt: Date(),
            children: nil, author: author
        )
        insert(optimistic, under: parentId, into: &replies)
        replyText = ""
        replyingTo = nil

        // Persist to Supabase
        Task {
            do {
                _ = try await replyService.createReply(
                    postId: post.id,
                    userId: userId,
                    text: trimmed,
                    parentReplyId: parentId,
                    depth: depth
                )
            } catch {
                print("Failed to persist reply: \(error)")
            }
        }
    }

    /// Insert a reply into the tree: appended at the root when `parentId` is nil,
    /// otherwise nested in the matching parent's children with depth one deeper
    /// (capped). Depth is recomputed here so it always matches nesting. Falls
    /// back to the root if the parent can't be found.
    func insert(_ reply: Reply, under parentId: UUID?, into nodes: inout [Reply]) {
        guard let parentId else {
            var r = reply
            r.depth = 0
            r.parentReplyId = nil
            nodes.append(r)
            return
        }
        if graft(reply, under: parentId, into: &nodes) { return }
        // Parent not found — don't silently drop it; show it at the root.
        var r = reply
        r.depth = 0
        r.parentReplyId = nil
        nodes.append(r)
    }

    @discardableResult
    func graft(_ reply: Reply, under parentId: UUID, into nodes: inout [Reply]) -> Bool {
        for i in nodes.indices {
            if nodes[i].id == parentId {
                var r = reply
                r.parentReplyId = parentId
                r.depth = min(nodes[i].depth + 1, Reply.maxDepth)
                nodes[i].children = (nodes[i].children ?? []) + [r]
                return true
            }
            if var kids = nodes[i].children {
                if graft(reply, under: parentId, into: &kids) {
                    nodes[i].children = kids
                    return true
                }
            }
        }
        return false
    }

    func voteOnReply(replyId: UUID, userId: UUID, direction: Int) {
        Task {
            try? await replyService.vote(replyId: replyId, userId: userId, direction: direction)
        }
    }
}
