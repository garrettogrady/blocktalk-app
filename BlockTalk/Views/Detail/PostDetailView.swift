import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var location
    @Environment(LocalContentStore.self) private var localContent
    @State private var viewModel = PostDetailViewModel()

    /// The current user's identity, embedded on replies they send.
    private var replyAuthor: ReplyAuthor {
        ReplyAuthor(
            username: appState.currentUser?.username ?? "BlockTalker",
            userNumber: appState.currentUser?.userNumber ?? 0,
            homeShortCode: appState.physicalNeighborhood?.shortCode ?? "LES"
        )
    }
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
                                    viewModel.voteOnReply(replyId: replyId, userId: userId, direction: direction)
                                }
                            )
                        }
                    }

                    // Bottom spacer for reply bar
                    Spacer(minLength: 100)
                }
            }
            .refreshable {
                await viewModel.loadReplies(for: post, store: localContent)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ShareHelper.sharePost(post)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.btText2)
                }
            }
        }
        .sheet(isPresented: $showPreFrame) {
            LocationPreFrameSheet()
        }
        .task {
            viewModel.post = post
            await viewModel.loadReplies(for: post, store: localContent)
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

            // Hate-speech warning
            if viewModel.replyHasHate {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "exclamationmark.octagon")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.btPink)
                    Text("Watch your language. BlockTalk doesn't allow hate speech.")
                        .font(BTFont.bodySemibold(size: 12))
                        .foregroundStyle(Color.btPink)
                    Spacer()
                }
                .padding(.horizontal, BTSpacing.lg)
                .padding(.top, BTSpacing.sm)
            }

            HStack(alignment: .bottom, spacing: BTSpacing.md) {
                TextField("Reply...", text: $viewModel.replyText, axis: .vertical)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(viewModel.replyHasHate ? Color.btPink : Color.btText)
                    .lineLimit(1...5)
                    .focused($replyFocused)
                    .onChange(of: viewModel.replyText) { _, v in
                        if v.count > replyLimit { viewModel.replyText = String(v.prefix(replyLimit)) }
                    }

                VStack(alignment: .trailing, spacing: BTSpacing.xs) {
                    // Character counter — muted 350 → orange 450 → pink 500
                    if viewModel.replyText.count >= replyWarnAt {
                        Text("\(viewModel.replyText.count)/\(replyLimit)")
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(replyCounterColor)
                    }

                    Button {
                        guard let userId = appState.currentUser?.id else { return }
                        replyFocused = false
                        viewModel.sendReply(post: post, userId: userId, author: replyAuthor, store: localContent)
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
        .background {
            Color.btSurface.ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var canSendReply: Bool {
        let trimmed = viewModel.replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && viewModel.replyText.count <= replyLimit && !viewModel.replyHasHate
    }

    private var replyCounterColor: Color {
        let n = viewModel.replyText.count
        if n >= replyLimit { return .btPink }
        if n >= 450 { return .btWarn }
        return .btText3
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
