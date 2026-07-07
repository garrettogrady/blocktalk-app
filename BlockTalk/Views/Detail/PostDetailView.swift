import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var location
    @State private var viewModel = PostDetailViewModel()
    @State private var showPreFrame = false
    @FocusState private var replyFocused: Bool

    private let replyLimit = 500
    private let replyWarnAt = 350

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Full post display at top
                    PostCard(post: post)
                        .padding(.bottom, BTSpacing.md)

                    Divider().background(Color.btLine)

                    // Reply count header
                    Text("\(post.replyCount) REPLIES")
                        .font(BTFont.mono(size: 11))
                        .foregroundStyle(Color.btText3)
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.vertical, BTSpacing.md)

                    // Threaded replies
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.replies) { reply in
                            ReplyNode(
                                reply: reply,
                                onReplyTap: { replyId, username in
                                    // Replies require physical presence — gate when ungated
                                    if location.permissionState == .granted {
                                        viewModel.replyingTo = (id: replyId, username: username)
                                        replyFocused = true
                                    } else {
                                        locationGateTap(location, showPreFrame: $showPreFrame)
                                    }
                                },
                                onVote: { replyId, direction in
                                    guard let userId = appState.currentUser?.id else { return }
                                    Task {
                                        await viewModel.voteOnReply(
                                            replyId: replyId,
                                            userId: userId,
                                            direction: direction
                                        )
                                    }
                                }
                            )
                        }
                    }

                    // Bottom spacer for reply bar
                    Spacer(minLength: 100)
                }
            }
            .refreshable {
                await viewModel.loadReplies(postId: post.id)
            }

            // Reply compose bar — replaced by the location gate when ungated
            if location.permissionState == .granted {
                replyBar
            } else {
                LocationGateBar(label: "Enable location to reply", showPreFrame: $showPreFrame)
            }
        }
        .background(Color.btBg)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPreFrame) {
            LocationPreFrameSheet()
        }
        .task {
            viewModel.post = post
            await viewModel.loadReplies(postId: post.id)
        }
    }

    // MARK: - Reply Bar

    private var replyBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.btLine)

            // Reply-to chip
            if let replyingTo = viewModel.replyingTo {
                HStack(spacing: BTSpacing.sm) {
                    Text("Replying to")
                        .font(BTFont.body(size: 12))
                        .foregroundStyle(Color.btText3)
                    Text("@\(replyingTo.username)")
                        .font(BTFont.bodySemibold(size: 12))
                        .foregroundStyle(Color.btLime)
                    Spacer()
                    Button {
                        viewModel.replyingTo = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.btText3)
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
                .padding(.top, BTSpacing.sm)
            }

            HStack(alignment: .bottom, spacing: BTSpacing.md) {
                TextField("Reply...", text: $viewModel.replyText, axis: .vertical)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText)
                    .lineLimit(1...5)
                    .focused($replyFocused)

                VStack(alignment: .trailing, spacing: BTSpacing.xs) {
                    // Character counter
                    if viewModel.replyText.count >= replyWarnAt {
                        Text("\(viewModel.replyText.count)/\(replyLimit)")
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(
                                viewModel.replyText.count > replyLimit
                                    ? Color.btPink : Color.btWarn
                            )
                    }

                    Button {
                        guard let userId = appState.currentUser?.id else { return }
                        Task {
                            await viewModel.sendReply(postId: post.id, userId: userId)
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                canSendReply ? Color.btLime : Color.btMuted
                            )
                    }
                    .disabled(!canSendReply)
                }
            }
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.md)
        }
        .background(Color.btSurface)
    }

    private var canSendReply: Bool {
        let trimmed = viewModel.replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && viewModel.replyText.count <= replyLimit
    }
}

#Preview {
    NavigationStack {
        PostDetailView(
            post: Post(
                id: UUID(),
                userId: UUID(),
                neighborhoodId: UUID(),
                text: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter.",
                isDailyPrompt: false,
                score: 42,
                replyCount: 7,
                reportCount: 0,
                status: .live
            )
        )
        .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
