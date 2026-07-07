import SwiftUI

struct ReplyNode: View {
    let reply: Reply
    var onReplyTap: ((_ replyId: UUID, _ username: String) -> Void)?
    var onVote: ((_ replyId: UUID, _ direction: Int) -> Void)?

    private let maxDepth = 3

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Thread lines on left (vertical bars), indent per depth
                if reply.depth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0 ..< reply.depth, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.btLine)
                                .frame(width: 1.5)
                                .padding(.horizontal, BTSpacing.md)
                        }
                    }
                }

                // Reply content
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    // Meta row
                    HStack(spacing: BTSpacing.xs) {
                        if let a = reply.author {
                            Text("@\(a.username)")
                                .font(BTFont.bodySemibold(size: 11))
                                .foregroundStyle(Color.btText)
                            Text("#\(a.userNumber.formatted(.number))")
                                .font(BTFont.monoBold(size: 11))
                                .foregroundStyle(Color.btLime)
                            HomeBadge(shortCode: a.homeShortCode)
                        }
                        if let createdAt = reply.createdAt {
                            Text("·").foregroundStyle(Color.btText3)
                            Text(timeAgo(createdAt))
                                .font(BTFont.mono(size: 11))
                                .foregroundStyle(Color.btText3)
                        }
                        Spacer(minLength: 0)
                    }

                    // Body text
                    Text(reply.text)
                        .font(BTFont.body(size: 14))
                        .foregroundStyle(Color.btText)
                        .lineSpacing(3)

                    // Action row
                    HStack(spacing: BTSpacing.lg) {
                        // Vote pills
                        VotePills(
                            score: reply.score,
                            onUpvote: {
                                onVote?(reply.id, 1)
                            },
                            onDownvote: {
                                onVote?(reply.id, -1)
                            }
                        )

                        // Flag icon
                        Button {
                            // Report reply
                        } label: {
                            Image(systemName: "flag")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.btText3)
                        }

                        Spacer()

                        // Reply pill (hidden at max depth), right-aligned
                        if reply.depth < maxDepth {
                            Button {
                                onReplyTap?(reply.id, reply.author?.username ?? "user")
                            } label: {
                                HStack(spacing: BTSpacing.xs) {
                                    Image(systemName: "arrowshape.turn.up.left")
                                        .font(.system(size: 11))
                                    Text("Reply")
                                        .font(BTFont.body(size: 12))
                                }
                                .foregroundStyle(Color.btText3)
                                .padding(.horizontal, BTSpacing.sm)
                                .padding(.vertical, BTSpacing.xs)
                                .background(Color.btSurface2)
                                .cornerRadius(BTRadius.full)
                            }
                        }
                    }
                }
                .padding(BTSpacing.lg)
            }

            Divider().background(Color.btLine)

            // Recursive children
            if let children = reply.children {
                ForEach(children) { child in
                    ReplyNode(
                        reply: child,
                        onReplyTap: onReplyTap,
                        onVote: onVote
                    )
                }
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: 0) {
            ReplyNode(
                reply: Reply(
                    id: UUID(),
                    postId: UUID(),
                    userId: UUID(),
                    text: "That cat is legendary. Been doing that for years.",
                    score: 12,
                    depth: 0,
                    createdAt: Date().addingTimeInterval(-300),
                    children: [
                        Reply(
                            id: UUID(),
                            postId: UUID(),
                            userId: UUID(),
                            text: "Facts. The owner doesn't even care anymore.",
                            score: 5,
                            depth: 1,
                            createdAt: Date().addingTimeInterval(-120)
                        ),
                    ]
                )
            )
        }
    }
}
