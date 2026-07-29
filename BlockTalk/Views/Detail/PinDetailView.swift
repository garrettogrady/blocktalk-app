import MapKit
import SwiftUI

struct PinDetailView: View {
    let pin: Pin
    let post: Post

    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var location
    @Environment(LocalContentStore.self) private var localContent
    @State private var viewModel = PostDetailViewModel()

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

    /// Route 2: business-tagged corners read house-blue, plain corners lime.
    private var isBusiness: Bool { pin.placeName != nil }
    private var tagColor: Color { isBusiness ? Color.btHouse : Color.btLime }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Map snippet at top
                    mapSnippet
                        .frame(height: 200)

                    // Featured pin post — hide its inline mini-map; the
                    // full-size map above already shows this corner.
                    PostCard(post: post, showStreetMap: false)

                    Divider().background(Color.btLine)

                    // Threaded replies
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.replies) { reply in
                            ReplyNode(
                                reply: reply,
                                onReplyTap: { replyId, username in
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

                    Spacer(minLength: 100)
                }
            }

            // Reply compose bar — replaced by the location gate when ungated
            if location.permissionState == .granted {
                replyComposeBar
            } else {
                LocationGateBar(label: "Enable location to reply on this corner", showPreFrame: $showPreFrame)
            }
        }
        .background(Color.btBg)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPreFrame) {
            LocationPreFrameSheet()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let label = pin.placeName ?? pin.cornerName {
                    Text("Pin · \(label)")
                        .font(BTFont.bodySemibold(size: 16))
                        .foregroundStyle(Color.btText)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ShareHelper.sharePost(post)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.btText2)
                }
            }
        }
        .task {
            viewModel.post = post
            await viewModel.loadReplies(for: post)
        }
    }

    // MARK: - Map Snippet

    private var mapSnippet: some View {
        ZStack(alignment: .topLeading) {
            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: pin.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            ), interactionModes: []) {
                Annotation("", coordinate: pin.coordinate) {
                    PulsatingPinView(
                        tint: tagColor,
                        symbol: isBusiness ? (pin.placeSymbol ?? "mappin.circle.fill") : nil
                    )
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)

            // "DROPPED · …" badge — business name (blue) or corner (lime)
            if let label = pin.placeName ?? pin.cornerName {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: isBusiness ? (pin.placeSymbol ?? "mappin.circle.fill") : "mappin.circle.fill")
                        .font(.system(size: 11))
                    Text("DROPPED · \(label.uppercased())")
                        .font(BTFont.monoBold(size: 10))
                }
                .foregroundStyle(Color.btBg)
                .padding(.horizontal, BTSpacing.md)
                .padding(.vertical, BTSpacing.xs)
                .background(tagColor)
                .cornerRadius(BTRadius.sm)
                .padding(BTSpacing.md)
            }
        }
    }

    // MARK: - Reply Compose Bar

    private var replyComposeBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.btLine)

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
                TextField("Reply on this corner…", text: $viewModel.replyText, axis: .vertical)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(viewModel.replyHasHate ? Color.btPink : Color.btText)
                    .lineLimit(1...5)
                    .focused($replyFocused)
                    .onChange(of: viewModel.replyText) { _, v in
                        if v.count > replyLimit { viewModel.replyText = String(v.prefix(replyLimit)) }
                    }

                VStack(alignment: .trailing, spacing: BTSpacing.xs) {
                    if viewModel.replyText.count >= replyWarnAt {
                        Text("\(viewModel.replyText.count)/\(replyLimit)")
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(replyCounterColor)
                    }
                    Button {
                        guard let userId = appState.currentUser?.id else { return }
                        replyFocused = false
                        viewModel.sendReply(post: post, userId: userId, author: replyAuthor)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(canSendReply ? Color.btLime : Color.btMuted)
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
        PinDetailView(
            pin: Pin(
                id: UUID(),
                userId: UUID(),
                latitude: 40.7193,
                longitude: -73.9911,
                cornerName: "7th & Ave A",
                neighborhoodId: UUID()
            ),
            post: Post(
                id: UUID(),
                userId: UUID(),
                neighborhoodId: UUID(),
                text: "This corner always smells like fresh bread at 6am",
                isDailyPrompt: false,
                score: 18,
                replyCount: 3,
                reportCount: 0,
                status: .live
            )
        )
        .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
