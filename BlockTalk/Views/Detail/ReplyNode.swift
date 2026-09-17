import SwiftUI

struct ReplyNode: View {
    let reply: Reply
    var onReplyTap: ((_ replyId: UUID, _ username: String) -> Void)?
    var onVote: ((_ replyId: UUID, _ direction: Int) -> Void)?

    @Environment(AppState.self) private var appState
    @Environment(ContentEditStore.self) private var edits
    @State private var showReport = false
    @State private var reported = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showHistory = false
    @State private var deleteError: String?

    /// The reply as it reads right now, including your own edits this session.
    private var shown: Reply { edits.apply(reply) }

    /// You can't report your own reply (same rule as posts).
    private var isOwnReply: Bool { reply.userId == appState.currentUser?.id }

    /// Live tier from the embedded author; your own replies fall back to your aura.
    private var authorLevel: AuthorityLevel? {
        if let aura = reply.author?.aura { return Authority.level(for: aura) }
        if isOwnReply, let aura = appState.currentUser?.aura { return Authority.level(for: aura) }
        return nil
    }

    // Visual indent cap (Reddit-mobile style): stop indenting past this depth so
    // deep threads don't run off the right edge — but replies are never blocked,
    // they just render at the capped indent.
    private let maxIndent = 3

    var body: some View {
        if edits.isHardDeleted(replyId: reply.id) {
            // Gone. A hard-deleted reply had no children, so nothing below it either.
            EmptyView()
        } else {
            node
        }
    }

    private var node: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Thread lines on left (vertical bars), indent per depth
                if reply.depth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0 ..< min(reply.depth, maxIndent), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.btLine)
                                .frame(width: 1.5)
                                .padding(.horizontal, BTSpacing.md)
                        }
                    }
                }

                // Reply content
                if shown.isDeleted {
                    ReplyDeletedRow()
                        .padding(BTSpacing.lg)
                } else {
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    // Meta row
                    HStack(spacing: 6) {
                        if let a = reply.author {
                            Text("@\(a.username)")
                                .font(BTFont.bodySemibold(size: 11))
                                .foregroundStyle(authorLevel?.tier.color ?? Color.btText)
                            Text("#\(a.userNumber.formatted(.number))")
                                .font(BTFont.mono(size: 11))
                                .foregroundStyle(Color.btText3)
                            if let level = authorLevel {
                                AuthorityBadge(level: level)
                            }
                            HomeBadge(shortCode: a.homeShortCode)
                        }
                        Spacer(minLength: 0)
                    }

                    // Body text
                    Text(shown.text)
                        .font(BTFont.body(size: 14))
                        .foregroundStyle(Color.btText)
                        .lineSpacing(3)

                    // Action row
                    HStack(spacing: 6) {
                        // Vote pills
                        VotePills(
                            score: reply.score,
                            upvoteCount: reply.upvoteCount,
                            downvoteCount: reply.downvoteCount,
                            onUpvote: {
                                onVote?(reply.id, 1)
                            },
                            onDownvote: {
                                onVote?(reply.id, -1)
                            }
                        )

                        // Flag — boxed to match the main comment's action buttons.
                        // Hidden on your own reply (you can't report yourself).
                        if !isOwnReply {
                            Button {
                                if !reported { showReport = true }
                            } label: {
                                Image(systemName: reported ? "flag.fill" : "flag")
                                    .font(.system(size: 13))
                                    .foregroundStyle(reported ? Color.btPink : Color.btText2)
                                    .frame(width: 30, height: 30)
                                    .background(reported ? Color.btPink.opacity(0.12) : Color.btSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BTRadius.sm)
                                            .stroke(reported ? Color.btPink.opacity(0.45) : Color.btLine, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
                            }
                            .buttonStyle(.plain)
                        } else {
                            ownerMenu
                        }

                        Spacer()

                        // Age sits here now (moved out of the meta row); replies have
                        // no reply count so it stands alone. "edited" opens the
                        // original-vs-now sheet.
                        if reply.createdAt != nil || shown.editedAt != nil {
                            Button { if shown.editedAt != nil { showHistory = true } } label: {
                                ageRun
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, BTSpacing.sm)
                        }

                        // Reply is always available — deep replies flatten to the
                        // capped indent, they aren't blocked.
                        if onReplyTap != nil {
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
            }
            .sheet(isPresented: $showReport) {
                ReportModalView(postId: reply.id, targetLabel: "reply") { _ in
                    reported = true
                }
            }
            .sheet(isPresented: $showEdit) {
                EditTextSheet(title: "Edit reply", limit: Reply.textLimit, original: shown.text) { newText in
                    await saveEdit(newText)
                }
            }
            .sheet(isPresented: $showHistory) {
                EditHistorySheet(original: shown.originalText ?? "", current: shown.text,
                                 originalAt: reply.createdAt, editedAt: shown.editedAt, noun: "reply")
            }
            .alert("Delete this reply?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { Task { await performDelete() } }
            } message: {
                let below = reply.descendantCount
                if below > 0 {
                    Text("Your text will be removed. The \(below) \(below == 1 ? "reply" : "replies") underneath it will stay. Other people wrote those.")
                } else {
                    Text("It'll be gone. This can't be undone.")
                }
            }
            .alert("Couldn't delete", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }

            Divider().background(Color.btLine)

            // Recursive children (survive a tombstoned parent)
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

    // MARK: - Owner actions

    private var ageRun: some View {
        var run = Text(reply.createdAt.map { RelativeTime.short(since: $0) } ?? "")
            .font(BTFont.mono(size: 11))
            .foregroundStyle(Color.btText3)
        if shown.editedAt != nil {
            run = run
                + Text(" · ").font(BTFont.mono(size: 11)).foregroundStyle(Color.btText3)
                + Text("edited").font(BTFont.mono(size: 11)).foregroundStyle(Color.btText3)
                    .underline(true, pattern: .dot, color: Color.btLine2)
        }
        return run.lineLimit(1).fixedSize()
    }

    private var ownerMenu: some View {
        Menu {
            Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Delete", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13))
                .foregroundStyle(Color.btText2)
                .frame(width: 30, height: 30)
                .background(Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.sm)
                        .stroke(Color.btLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
        }
        .accessibilityLabel("More")
    }

    private func saveEdit(_ newText: String) async -> String? {
        do {
            let result = try await ContentEditingService().editReply(id: reply.id, text: newText)
            edits.recordEdit(replyId: reply.id, .init(
                text: result.text ?? newText,
                originalText: result.originalText,
                editedAt: (result.marked ?? false) ? Date() : shown.editedAt,
                editCount: result.editCount
            ))
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func performDelete() async {
        do {
            let result = try await ContentEditingService().deleteReply(id: reply.id)
            switch result.outcome {
            case .hard: edits.recordHardDelete(replyId: reply.id)
            case .tombstone, .none: edits.recordTombstone(replyId: reply.id)
            }
        } catch {
            deleteError = error.localizedDescription
        }
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
                    upvoteCount: 13,
                    downvoteCount: 1,
                    depth: 0,
                    createdAt: Date().addingTimeInterval(-300),
                    children: [
                        Reply(
                            id: UUID(),
                            postId: UUID(),
                            userId: UUID(),
                            text: "Facts. The owner doesn't even care anymore.",
                            score: 5,
                            upvoteCount: 5,
                            downvoteCount: 0,
                            depth: 1,
                            createdAt: Date().addingTimeInterval(-120)
                        ),
                    ]
                )
            )
        }
        .environment(AppState())
        .environment(ContentEditStore())
    }
}
