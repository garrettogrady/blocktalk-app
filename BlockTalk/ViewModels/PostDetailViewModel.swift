import Foundation

@Observable
final class PostDetailViewModel {
    var post: Post?
    var replies: [Reply] = []
    var isLoading = false
    var error: String?
    var replyText = ""
    var replyingTo: (id: UUID, username: String)?

    private let postService = PostService()
    private let replyService = ReplyService()

    func loadPost(id: UUID) async {
        isLoading = true
        // Post is typically passed in from the feed
        isLoading = false
    }

    func loadReplies(postId: UUID) async {
        isLoading = true
        do {
            replies = try await replyService.fetchReplies(postId: postId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func sendReply(postId: UUID, userId: UUID) async {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !LanguageCheck.containsHateSpeech(trimmed) else { return }

        do {
            let depth = replyingTo != nil ? min(Reply.maxDepth, 1) : 0
            let reply = try await replyService.createReply(
                postId: postId,
                userId: userId,
                text: trimmed,
                parentReplyId: replyingTo?.id,
                depth: depth
            )
            replies.append(reply)
            replyText = ""
            replyingTo = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func voteOnReply(replyId: UUID, userId: UUID, direction: Int) async {
        do {
            try await replyService.vote(replyId: replyId, userId: userId, direction: direction)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
