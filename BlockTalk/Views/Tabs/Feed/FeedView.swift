import Combine
import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @Environment(OfflineStore.self) private var offline
    @State private var viewModel = FeedViewModel()
    @State private var showCompose = false
    @State private var showNeighborhoodPicker = false
    @State private var showPreFrame = false
    @State private var showSearch = false

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
                            DailyPromptCard(prompt: prompt)
                        }

                        // Location / neighborhood row
                        locationRow
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, BTSpacing.lg)

                        // Sort/time filters
                        SortTimeFilters(
                            sort: $viewModel.sort,
                            timeFilter: $viewModel.timeFilter
                        )
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.top, BTSpacing.md)

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

                // Bottom bar: compose if location granted, location gate if not
                if locationService.permissionState == .granted {
                    ComposeBarView {
                        showCompose = true
                    }
                } else {
                    LocationGateBar(showPreFrame: $showPreFrame)
                }
            }
            .background(Color.btBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("block")
                            .font(BTFont.display(size: 20))
                            .foregroundStyle(Color.btText)
                        Text(".")
                            .font(BTFont.display(size: 20))
                            .foregroundStyle(Color.btLime)
                        Text("talk")
                            .font(BTFont.display(size: 20))
                            .foregroundStyle(Color.btText)
                    }
                }
            }
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
            .sheet(isPresented: $showNeighborhoodPicker) {
                NeighborhoodPickerView(currentValue: appState.viewingNeighborhood) { neighborhood in
                    appState.viewingNeighborhood = neighborhood
                    viewModel.viewingNeighborhood = neighborhood
                    Task { await viewModel.loadPosts() }
                }
            }
            .sheet(isPresented: $showPreFrame) {
                LocationPreFrameSheet()
            }
            .sheet(isPresented: $showSearch) {
                SearchView(scope: .neighborhood, neighborhood: appState.viewingNeighborhood)
            }
        }
    }

    // MARK: - Location Row

    private var locationRow: some View {
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
