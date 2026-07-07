import MapKit
import SwiftUI

struct PinDetailView: View {
    let pin: Pin
    let post: Post

    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var location
    @State private var viewModel = PostDetailViewModel()
    @State private var showPreFrame = false
    @FocusState private var replyFocused: Bool

    private let replyLimit = 500

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Map snippet at top
                    mapSnippet
                        .frame(height: 200)

                    // Featured pin post
                    PostCard(post: post)

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
                if let cornerName = pin.cornerName {
                    Text(cornerName)
                        .font(BTFont.bodySemibold(size: 16))
                        .foregroundStyle(Color.btText)
                }
            }
        }
        .task {
            viewModel.post = post
            await viewModel.loadReplies(postId: post.id)
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
                    PulsatingPinView()
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)

            // "DROPPED · CORNER NAME" badge
            if let cornerName = pin.cornerName {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                    Text("DROPPED · \(cornerName.uppercased())")
                        .font(BTFont.monoBold(size: 10))
                }
                .foregroundStyle(Color.btBg)
                .padding(.horizontal, BTSpacing.md)
                .padding(.vertical, BTSpacing.xs)
                .background(Color.btLime)
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

            HStack(alignment: .bottom, spacing: BTSpacing.md) {
                TextField("Reply on this corner…", text: $viewModel.replyText, axis: .vertical)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText)
                    .lineLimit(1...5)
                    .focused($replyFocused)

                Button {
                    guard let userId = appState.currentUser?.id else { return }
                    Task {
                        await viewModel.sendReply(postId: post.id, userId: userId)
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            viewModel.replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.btMuted : Color.btLime
                        )
                }
                .disabled(viewModel.replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.md)
        }
        .background(Color.btSurface)
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
