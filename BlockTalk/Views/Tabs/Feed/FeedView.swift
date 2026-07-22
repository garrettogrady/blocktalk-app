import Combine
import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @Environment(OfflineStore.self) private var offline
    @Environment(LocalContentStore.self) private var localContent
    @State private var viewModel = FeedViewModel()
    @State private var showCompose = false
    @State private var showNeighborhoodPicker = false
    @State private var showPreFrame = false
    @State private var showSearch = false
    /// One-time nudge toward the map — the sexiest feature, otherwise buried in
    /// tab 2. Dismissible so it never becomes permanent chrome.
    @AppStorage("hasSeenMapTip") private var hasSeenMapTip = false

    /// Posts the user created this session for the neighborhood being viewed.
    private var myPosts: [Post] {
        guard let viewingId = appState.viewingNeighborhood?.id else { return [] }
        return localContent.posts(in: viewingId)
    }

    private var isViewingHome: Bool {
        guard let homeId = appState.currentUser?.homeNeighborhoodId,
              let viewingId = appState.viewingNeighborhood?.id else { return false }
        return homeId == viewingId
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Location gate banner at top when location not granted
                        LocationGateBanner(showPreFrame: $showPreFrame)

                        // Offline banner
                        if offline.isOffline {
                            OfflineBanner(pendingPostCount: offline.pending.count)
                        }

                        // Daily prompt card — full-width strip
                        if let prompt = viewModel.dailyPrompt {
                            DailyPromptCard(prompt: prompt, answerCount: 1842)
                        }

                        // Location / neighborhood row
                        locationRow
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, BTSpacing.md)
                            .padding(.bottom, BTSpacing.sm)

                        // Separator under the neighborhood/search header row
                        // (matches the Expo mock's locRow bottom border).
                        Divider().background(Color.btLine)

                        // Sort/time filters
                        SortTimeFilters(
                            sort: $viewModel.sort,
                            timeFilter: $viewModel.timeFilter
                        )
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.top, BTSpacing.sm)

                        // One-time map nudge
                        if !hasSeenMapTip {
                            mapTip
                                .padding(.horizontal, BTSpacing.lg)
                                .padding(.top, BTSpacing.md)
                        }

                        // Offline: discarded (top) → pending → flushed, above the feed
                        if !offline.discarded.isEmpty {
                            VStack(spacing: BTSpacing.md) {
                                ForEach(offline.discarded) { q in
                                    DiscardedPostRow(post: q.post) { offline.dismissDiscarded(q.id) }
                                }
                            }
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, BTSpacing.md)
                        }

                        if !offline.pending.isEmpty || !offline.flushed.isEmpty {
                            LazyVStack(spacing: 0) {
                                ForEach(offline.pending) { q in
                                    PostCard(post: q.post, pending: true,
                                             username: appState.currentUser?.username ?? "BlockTalker",
                                             userNumber: appState.currentUser?.userNumber ?? 0,
                                             homeShortCode: appState.viewingNeighborhood?.shortCode)
                                    Divider().background(Color.btLine)
                                }
                                ForEach(offline.flushed) { post in
                                    NavigationLink(value: post) {
                                        PostCard(post: post,
                                                 username: appState.currentUser?.username ?? "BlockTalker",
                                                 userNumber: appState.currentUser?.userNumber ?? 0,
                                                 homeShortCode: appState.viewingNeighborhood?.shortCode)
                                    }
                                    .buttonStyle(.plain)
                                    Divider().background(Color.btLine)
                                }
                            }
                            .padding(.top, BTSpacing.sm)
                        }

                        // Posts you created this session (bundled-mock, no
                        // backend) — shown on top of the sample feed.
                        if !myPosts.isEmpty {
                            LazyVStack(spacing: 0) {
                                ForEach(myPosts) { post in
                                    NavigationLink(value: post) {
                                        PostCard(post: post)
                                    }
                                    .buttonStyle(.plain)
                                    Divider().background(Color.btLine)
                                }
                            }
                            .padding(.top, BTSpacing.sm)
                        }

                        // Posts
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(Color.btText3)
                                .padding(.top, BTSpacing.xxxl)
                        } else if viewModel.posts.isEmpty {
                            VStack(spacing: BTSpacing.md) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.btText3)
                                Text("No posts yet")
                                    .font(BTFont.body(size: 15))
                                    .foregroundStyle(Color.btText3)
                                Text("Be the first to post in this neighborhood.")
                                    .font(BTFont.body(size: 13))
                                    .foregroundStyle(Color.btMuted)
                            }
                            .padding(.top, BTSpacing.xxxl)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.posts) { post in
                                    NavigationLink(value: post) {
                                        PostCard(post: post)
                                    }
                                    .buttonStyle(.plain)

                                    Divider()
                                        .background(Color.btLine)
                                }
                            }
                            .padding(.top, BTSpacing.sm)
                        }

                        // Bottom spacer for compose bar
                        Spacer(minLength: 80)
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                    // Age pending posts past the grace window into discarded
                    offline.expireStale()
                }

                // Bottom bar: location gate if not granted; compose if you're
                // viewing the block you're physically in; otherwise a browse-only
                // notice (you can read here but only post where you actually are).
                if locationService.permissionState != .granted {
                    LocationGateBar(showPreFrame: $showPreFrame)
                } else if appState.canPostInViewing {
                    ComposeBarView {
                        showCompose = true
                    }
                } else {
                    browseOnlyBar
                }
            }
            .background(Color.btBg)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .sheet(isPresented: $showCompose) {
                ComposeView(postingNeighborhood: appState.viewingNeighborhood)
            }
            .task {
                if !appState.hasResolvedInitialNeighborhood {
                    await resolveInitialNeighborhood()
                }
                // Sync viewModel with appState on appear
                viewModel.viewingNeighborhood = appState.viewingNeighborhood
                await viewModel.loadDailyPrompt()
                if viewModel.posts.isEmpty {
                    await viewModel.loadPosts()
                }
            }
            .onChange(of: locationService.currentNeighborhood) { _, newNeighborhood in
                // GPS resolved — override home fallback if we haven't set by location yet
                if let neighborhood = newNeighborhood, !appState.hasResolvedInitialNeighborhood {
                    appState.viewingNeighborhood = neighborhood
                    appState.hasResolvedInitialNeighborhood = true
                    viewModel.viewingNeighborhood = neighborhood
                    Task { await viewModel.loadPosts() }
                }
            }
            .onChange(of: appState.viewingNeighborhood) { _, newNeighborhood in
                // Keep viewModel in sync when neighborhood changes (e.g. from picker or map)
                if viewModel.viewingNeighborhood?.id != newNeighborhood?.id {
                    viewModel.viewingNeighborhood = newNeighborhood
                    Task { await viewModel.loadPosts() }
                }
            }
            .fullScreenCover(isPresented: $showNeighborhoodPicker) {
                NeighborhoodPickerView(
                    currentValue: appState.viewingNeighborhood,
                    title: "Viewing Neighborhood",
                    confirmCta: { "View \($0)" }
                ) { neighborhood in
                    appState.viewingNeighborhood = neighborhood
                    viewModel.viewingNeighborhood = neighborhood
                    Task { await viewModel.loadPosts() }
                }
            }
            .sheet(isPresented: $showPreFrame) {
                LocationPreFrameSheet()
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchView(scope: .neighborhood, neighborhood: appState.viewingNeighborhood)
            }
        }
    }

    // MARK: - Map nudge

    /// Slim, one-time teaser pointing at the map — where street comments live on
    /// the real corner. Tapping opens the Map tab; the × just dismisses it.
    private var mapTip: some View {
        Button {
            hasSeenMapTip = true
            appState.selectedTab = 1
        } label: {
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: "map.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.btHouse)
                (Text("Street comments live on the map. ")
                    .font(BTFont.bodySemibold(size: 12)).foregroundColor(.btText)
                 + Text("See the actual corners →")
                    .font(BTFont.body(size: 12)).foregroundColor(.btText2))
                    .lineLimit(2)
                Spacer(minLength: BTSpacing.sm)
                Button {
                    hasSeenMapTip = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.btText3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.btHouse.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btHouse.opacity(0.28), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Location locking

    /// True when you're reading a neighborhood you're not physically in — the
    /// note lives under the VIEWING dropdown (see locationRow).
    private var isBrowsingElsewhere: Bool {
        locationService.permissionState == .granted
            && appState.physicalNeighborhood != nil
            && appState.viewingNeighborhood != nil
            && !appState.canPostInViewing
    }

    /// Replaces the compose bar when you're viewing a block you're not in —
    /// you can read, but posting is locked to where you actually are.
    private var browseOnlyBar: some View {
        Button {
            if let home = appState.physicalNeighborhood { appState.viewingNeighborhood = home }
        } label: {
            HStack(spacing: BTSpacing.sm) {
                HStack(spacing: BTSpacing.sm) {
                    Image(systemName: "eye").font(.system(size: 14)).foregroundStyle(Color.btHouse)
                    Text("browsing only · post in \(appState.physicalNeighborhood?.name ?? "your block")")
                        .font(BTFont.bodySemibold(size: 12))
                        .foregroundStyle(Color.btText)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .frame(height: 38)
                .padding(.horizontal, BTSpacing.md)
                .background(Color.btSurface)
                .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btHouse.opacity(0.35), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.btOnAccent)
                    .frame(width: 38, height: 38)
                    .background(Color.btHouse)
                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                Color.btBg.overlay(Color.btHouse.opacity(0.06))
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .overlay(alignment: .top) {
                Rectangle().fill(Color.btHouse.opacity(0.35)).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Location Row

    private var locationRow: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack(spacing: BTSpacing.sm) {
                Button {
                    showNeighborhoodPicker = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VIEWING")
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(Color.btText3)

                        HStack(spacing: BTSpacing.sm) {
                            // 🏠 only when viewing == home neighborhood
                            if isViewingHome {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.btHouse)
                            }

                            Text(appState.viewingNeighborhood?.name ?? "Locating...")
                                .font(BTFont.display(size: 18))
                                .foregroundStyle(Color.btText)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.btText3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, BTSpacing.sm)
                }
                .buttonStyle(.plain)

                // 38×38 within-neighborhood search
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.btText2)
                        .frame(width: 38, height: 38)
                        .background(Color.btSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.md)
                                .stroke(Color.btLine, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                }
                .buttonStyle(.plain)
            }

            // Browsing a block you're not in — a distinct, tappable control that
            // sends you back to where you can actually post.
            if isBrowsingElsewhere, let home = appState.physicalNeighborhood {
                Button {
                    withAnimation { appState.viewingNeighborhood = home }
                } label: {
                    HStack(spacing: BTSpacing.sm) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .semibold))
                        (Text("You can only post in ")
                         + Text(home.name).font(BTFont.bodyBold(size: 12.5)))
                            .font(BTFont.body(size: 12.5))
                        Spacer(minLength: BTSpacing.sm)
                        Text("Go there")
                            .font(BTFont.bodyBold(size: 12))
                    }
                    .foregroundStyle(Color.btHouse)
                    .padding(.horizontal, BTSpacing.md)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(Color.btHouse.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btHouse.opacity(0.4), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func resolveInitialNeighborhood() async {
        // GPS-resolved neighborhood first
        if let locationNeighborhood = locationService.currentNeighborhood {
            appState.viewingNeighborhood = locationNeighborhood
            appState.hasResolvedInitialNeighborhood = true
            return
        }

        // Fall back to user's home neighborhood
        if let homeId = appState.currentUser?.homeNeighborhoodId {
            do {
                let neighborhoods: [Neighborhood] = try await supabase.from("neighborhoods")
                    .select("id, name, short_code, borough")
                    .eq("id", value: homeId.uuidString)
                    .execute()
                    .value

                if let home = neighborhoods.first {
                    appState.viewingNeighborhood = home
                }
            } catch {
                print("Failed to fetch home neighborhood: \(error)")
            }
        }

        appState.hasResolvedInitialNeighborhood = true
    }
}

#Preview {
    FeedView()
        .environment(AppState())
        .environment(LocationService())
        .preferredColorScheme(.dark)
}
