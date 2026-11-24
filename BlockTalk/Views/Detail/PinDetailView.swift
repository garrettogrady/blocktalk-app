import MapKit
import SwiftUI

struct PinDetailView: View {
    let pin: Pin
    let post: Post
    /// Other posts tagged to the same business, when this thread was opened from
    /// that business's list. Shows a row that leads back to the list.
    var morePostsAtPlace: Int = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var location
    @Environment(LocalContentStore.self) private var localContent
    @Environment(BlockStore.self) private var blockStore
    @State private var viewModel = PostDetailViewModel()

    private var replyAuthor: ReplyAuthor {
        ReplyAuthor(
            username: appState.currentUser?.username ?? "BlockTalker",
            userNumber: appState.currentUser?.userNumber ?? 0,
            // Identity badge = the neighborhood you're FROM (home), matching post badges.
            homeShortCode: appState.homeNeighborhood?.shortCode
                ?? appState.physicalNeighborhood?.shortCode ?? "NYC",
            aura: appState.currentUser?.aura
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
                        ForEach(viewModel.replies.filter { !blockStore.isBlocked($0.userId) }) { reply in
                            ReplyNode(
                                reply: reply,
                                onReplyTap: { replyId, username in
                                    // Replies aren't presence-gated — same as PostDetailView.
                                    // Only posts + pins require you to be here.
                                    viewModel.replyingTo = (id: replyId, username: username)
                                    replyFocused = true
                                },
                                onVote: { replyId, direction in
                                    guard let userId = appState.currentUser?.id else { return }
                                    viewModel.voteOnReply(replyId: replyId, userId: userId, direction: direction)
                                }
                            )
                        }
                    }

                    if morePostsAtPlace > 0, let place = pin.placeName {
                        Button { dismiss() } label: {
                            HStack {
                                Text("\(morePostsAtPlace) more \(morePostsAtPlace == 1 ? "post" : "posts") at \(place)")
                                    .font(BTFont.bodySemibold(size: 14))
                                    .lineLimit(1)
                                Spacer(minLength: BTSpacing.sm)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(Color.btHouse)
                            .padding(.horizontal, BTSpacing.md)
                            .frame(minHeight: 48)
                            .background(Color.btSurface)
                            .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.top, BTSpacing.lg)
                    }

                    Spacer(minLength: 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Reply compose bar — replies aren't presence-gated (reading is global,
            // so replying is too; posts + pins still require presence).
            replyComposeBar
        }
        .background(Color.btBg)
        .navigationBarTitleDisplayMode(.inline)
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
        VStack(spacing: BTSpacing.xs) {
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

            // Char counter — above the pill, only near the limit
            if viewModel.replyText.count >= replyWarnAt {
                HStack {
                    Spacer()
                    Text("\(viewModel.replyText.count)/\(replyLimit)")
                        .font(BTFont.mono(size: 10))
                        .foregroundStyle(replyCounterColor)
                }
                .padding(.horizontal, BTSpacing.lg)
            }

            // Input pill — mirrors the feed compose bar, inline-editable.
            HStack(spacing: BTSpacing.md) {
                TextField("Reply on this corner…", text: $viewModel.replyText, axis: .vertical)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(viewModel.replyHasHate ? Color.btPink : Color.btText)
                    .lineLimit(1...5)
                    .focused($replyFocused)
                    .onChange(of: viewModel.replyText) { _, v in
                        if v.count > replyLimit { viewModel.replyText = String(v.prefix(replyLimit)) }
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
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.sm)
            .background(Color.btSurface)
            .cornerRadius(BTRadius.full)
            .overlay(RoundedRectangle(cornerRadius: BTRadius.full).stroke(Color.btLine, lineWidth: 1))
            .padding(.horizontal, BTSpacing.lg)
            .padding(.bottom, BTSpacing.sm)
        }
        .background {
            Color.btBg.ignoresSafeArea(.container, edges: .bottom)
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

// MARK: - Place group (several street comments tagged to the same business)

/// Business-tagged pins that share a name and sit on the same spot. A tagged
/// pin snaps to the business's own coordinate, so two people posting about the
/// same place produce pins stacked exactly on top of each other, and only the
/// top one could ever be tapped. The map draws ONE marker for the group and
/// opens a list of everything said there.
struct PlaceGroup: Identifiable {
    let id: String
    let name: String
    let symbol: String
    /// Newest first. Never empty.
    let pins: [Pin]

    var coordinate: CLLocationCoordinate2D { pins[0].coordinate }
    var neighborhoodId: UUID { pins[0].neighborhoodId }
    var category: String { pins.compactMap(\.placeCategory).first ?? "" }
    var cornerName: String? { pins.compactMap(\.cornerName).first }

    /// Same business = same name (case-insensitive) on the same ~10 m spot.
    /// Nil for a plain corner pin, which never groups.
    static func key(for pin: Pin) -> String? {
        guard let name = pin.placeName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !name.isEmpty else { return nil }
        let lat = Int((pin.latitude * 10_000).rounded())
        let lng = Int((pin.longitude * 10_000).rounded())
        return "\(name)|\(lat)|\(lng)"
    }

    /// Splits pins into businesses with 2+ posts (grouped) and everything else
    /// (drawn exactly as before).
    static func partition(_ pins: [Pin]) -> (groups: [PlaceGroup], singles: [Pin]) {
        var buckets: [String: [Pin]] = [:]
        var order: [String] = []
        var singles: [Pin] = []
        for pin in pins {
            guard let key = key(for: pin) else { singles.append(pin); continue }
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(pin)
        }
        var groups: [PlaceGroup] = []
        for key in order {
            let bucket = buckets[key] ?? []
            if bucket.count < 2 {
                singles.append(contentsOf: bucket)
                continue
            }
            let sorted = bucket.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            groups.append(PlaceGroup(
                id: key,
                name: sorted[0].placeName ?? "",
                symbol: sorted.compactMap(\.placeSymbol).first ?? "mappin.circle.fill",
                pins: sorted))
        }
        return (groups, singles)
    }
}

/// Map marker for a business with several posts: its glyph plus the count.
struct PlaceGroupMarker: View {
    let symbol: String
    let count: Int

    var body: some View {
        ZStack {
            // Invisible hit target
            Color.clear
                .frame(width: 60, height: 44)
                .contentShape(Rectangle())

            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                Text("\(count)")
                    .font(BTFont.monoBold(size: 13))
            }
            .foregroundStyle(Color.btBg)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Color.btHouse)
            .clipShape(Capsule())
            .background(
                Capsule()
                    .fill(Color.btHouse.opacity(0.2))
                    .padding(-6)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) posts here")
        .accessibilityAddTraits(.isButton)
    }
}

/// Everything said at one business, newest first. Presented from the map inside
/// a NavigationStack; a row pushes that post's usual pin thread.
struct PlacePostsView: View {
    let group: PlaceGroup
    /// Nil hides the "Say something" bar (you can only post where you are).
    var onAddPost: (() -> Void)?

    @Environment(LocalContentStore.self) private var localContent
    @Environment(BlockStore.self) private var blockStore
    @Environment(PinStore.self) private var pinStore
    @Environment(\.dismiss) private var dismiss
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var failed = false

    private var visiblePosts: [Post] {
        posts.filter { !blockStore.isBlocked($0.userId) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                Divider().background(Color.btLine)

                if isLoading && posts.isEmpty {
                    ProgressView()
                        .tint(Color.btText3)
                        .frame(maxWidth: .infinity)
                        .padding(.top, BTSpacing.xxxl)
                } else if failed && posts.isEmpty {
                    LoadErrorView { Task { await load() } }
                        .frame(maxWidth: .infinity)
                        .padding(.top, BTSpacing.xxxl)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(visiblePosts) { post in
                            NavigationLink(value: post) {
                                // The header already names the place and the map
                                // is one swipe away, so no per-row mini-map.
                                PostCard(post: post, showStreetMap: false)
                            }
                            .buttonStyle(.plain)
                            Divider().background(Color.btLine)
                        }
                    }
                }

                Spacer(minLength: onAddPost == nil ? BTSpacing.xxxl : 90)
            }
        }
        .background(Color.btBg)
        .safeAreaInset(edge: .bottom) {
            if let onAddPost { addBar(onAddPost) }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.btText2)
                }
                .accessibilityLabel("Close")
            }
        }
        .navigationDestination(for: Post.self) { post in
            if let pin = group.pins.first(where: { $0.id == post.pinId }) {
                PinDetailView(pin: pin, post: post, morePostsAtPlace: max(visiblePosts.count - 1, 0))
            }
        }
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack(spacing: BTSpacing.md) {
                Circle()
                    .fill(Color.btHouse)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: group.symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.btBg)
                    }
                Text(group.name)
                    .font(BTFont.display(size: 24))
                    .foregroundStyle(Color.btText)
                    .lineLimit(2)
            }
            (Text("\(countLabel)").font(BTFont.monoBold(size: 11)).foregroundColor(.btHouse)
             + Text(subline).font(BTFont.mono(size: 11)).foregroundColor(.btText2))
        }
        .padding(.horizontal, BTSpacing.xl)
        .padding(.top, BTSpacing.lg)
        .padding(.bottom, BTSpacing.lg)
    }

    private var countLabel: String {
        // Until the posts load, the pin count is the best number we have.
        let n = posts.isEmpty ? group.pins.count : visiblePosts.count
        return "\(n) \(n == 1 ? "POST" : "POSTS")"
    }

    private var subline: String {
        var s = ""
        if let corner = group.cornerName, !corner.isEmpty { s += " · \(corner.uppercased())" }
        return s + " · NEWEST FIRST"
    }

    private func addBar(_ action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Divider().background(Color.btLine)
            Button(action: action) {
                HStack(spacing: BTSpacing.md) {
                    Text("Say something about \(group.name)…")
                        .font(BTFont.body(size: 15))
                        .foregroundStyle(Color.btText2)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.btHouse)
                }
                .padding(.leading, BTSpacing.lg)
                .padding(.trailing, BTSpacing.sm)
                .frame(minHeight: 48)
                .background(Color.btSurface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.btLine, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.sm)
        }
        .background(Color.btBg)
    }

    private func load() async {
        isLoading = true
        failed = false
        // Posts made this session may not be in the fetch yet; start from those.
        let local = group.pins.compactMap { localContent.post(forPinId: $0.id) }
        var merged: [UUID: Post] = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        do {
            let fetched = try await PostService().fetchPosts(forPinIds: group.pins.map(\.id))
            for post in fetched { merged[post.id] = post }
        } catch {
            failed = true
            print("Failed to load posts for place \(group.name): \(error)")
        }
        posts = merged.values
            .filter { $0.status == .live }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        isLoading = false
        await pinStore.ensureLoaded(for: posts)
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
                upvoteCount: 20,
                downvoteCount: 2,
                replyCount: 3,
                reportCount: 0,
                status: .live
            )
        )
        .environment(AppState())
        .environment(EnrollmentStore())
    }
    .preferredColorScheme(.dark)
}
