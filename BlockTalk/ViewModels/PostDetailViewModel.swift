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

    /// Bundled-mock: the seeded per-post thread (keyed by the post's text) with
    /// any replies you've added this session grafted into the tree at the right
    /// parent. [PROD-DIFF: replyService.fetchReplies with the nested join.]
    func loadReplies(for post: Post, store: LocalContentStore) async {
        isLoading = true
        var thread = Reply.seededThread(forPostText: post.text)
        // Re-insert session replies in send order so a reply-to-a-reply lands
        // under its parent (which may itself be an earlier session reply).
        for r in store.replies(forPost: post.id) {
            insert(r, under: r.parentReplyId, into: &thread)
        }
        replies = thread
        isLoading = false
    }

    /// Bundled-mock: build the reply locally, nest it under the reply it answers
    /// (or at the root for a top-level reply), persist it, and show it
    /// immediately. [PROD-DIFF: replyService.createReply Supabase insert.]
    func sendReply(post: Post, userId: UUID, author: ReplyAuthor, store: LocalContentStore) {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !LanguageCheck.containsHateSpeech(trimmed) else { return }

        let reply = Reply(
            id: UUID(), postId: post.id, parentReplyId: replyingTo?.id, userId: userId,
            text: trimmed, score: 0, depth: 0, createdAt: Date(),
            children: nil, author: author
        )
        store.addReply(reply, toPost: post.id)
        insert(reply, under: replyingTo?.id, into: &replies)
        replyText = ""
        replyingTo = nil
    }

    /// Insert a reply into the tree: appended at the root when `parentId` is nil,
    /// otherwise nested in the matching parent's children with depth one deeper
    /// (capped). Depth is recomputed here so it always matches nesting. Falls
    /// back to the root if the parent can't be found.
    private func insert(_ reply: Reply, under parentId: UUID?, into nodes: inout [Reply]) {
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
    private func graft(_ reply: Reply, under parentId: UUID, into nodes: inout [Reply]) -> Bool {
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

    /// No model mutation: VotePills owns the vote display locally (optimistic
    /// count + toggle), same as post votes. [PROD-DIFF: replyService.vote.]
    func voteOnReply(replyId: UUID, userId: UUID, direction: Int) {}
}
