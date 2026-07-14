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

    /// Bundled-mock: the seeded per-post thread (keyed by the post's text) plus
    /// any replies you've added this session. [PROD-DIFF: replyService.fetchReplies.]
    func loadReplies(for post: Post, store: LocalContentStore) async {
        isLoading = true
        var thread = Reply.seededThread(forPostText: post.text)
        thread.append(contentsOf: store.replies(forPost: post.id))
        replies = thread
        isLoading = false
    }

    /// Bundled-mock: build the reply locally, persist it for the session, and
    /// show it immediately. [PROD-DIFF: replyService.createReply Supabase insert.]
    func sendReply(post: Post, userId: UUID, author: ReplyAuthor, store: LocalContentStore) {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !LanguageCheck.containsHateSpeech(trimmed) else { return }

        let depth = replyingTo != nil ? min(Reply.maxDepth, 1) : 0
        let reply = Reply(
            id: UUID(), postId: post.id, parentReplyId: replyingTo?.id, userId: userId,
            text: trimmed, score: 0, depth: depth, createdAt: Date(),
            children: nil, author: author
        )
        store.addReply(reply, toPost: post.id)
        replies.append(reply)
        replyText = ""
        replyingTo = nil
    }

    /// Local score bump (no backend in the mock).
    func voteOnReply(replyId: UUID, userId: UUID, direction: Int) {
        // Session-only: replies are value types in a tree; a full re-score walk
        // isn't needed for the demo. No-op keeps the tap from erroring.
    }
}
