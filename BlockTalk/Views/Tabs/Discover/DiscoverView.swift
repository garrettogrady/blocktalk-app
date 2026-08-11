import SwiftUI

struct DiscoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(NeighborhoodCache.self) private var neighborhoodCache
    @Environment(PinStore.self) private var pinStore
    @State private var viewModel = DiscoverViewModel()
    @State private var showSearch = false

    private let boroughs = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xxl) {
                    // Title + search (grouped tight)
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("Discover")
                            .font(BTFont.display(size: 30))
                            .foregroundStyle(Color.btText)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, BTSpacing.sm)

                    // Search bar
                    Button {
                        showSearch = true
                    } label: {
                        HStack(spacing: BTSpacing.md) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.btText3)
                            Text("Search across NYC")
                                .font(BTFont.body(size: 15))
                                .foregroundStyle(Color.btText3)
                            Spacer()
                        }
                        .padding(BTSpacing.md)
                        .background(Color.btSurface)
                        .cornerRadius(BTRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.md)
                                .stroke(Color.btLine, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, BTSpacing.lg)
                    }

                    // Content — loading / error / sections (a failed load must
                    // not read as an empty Discover).
                    if viewModel.isLoading && viewModel.trendingPosts.isEmpty {
                        ProgressView()
                            .tint(Color.btText3)
                            .frame(maxWidth: .infinity)
                            .padding(.top, BTSpacing.xxxl)
                    } else if viewModel.error != nil && viewModel.trendingPosts.isEmpty {
                        LoadErrorView { Task { await viewModel.load() } }
                    } else {
                    // Top by Borough — above the feed so it's always reachable
                    // (the paginated feed below grows downward and would otherwise
                    // bury these). [Reorder: git revert this commit for the old order.]
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("🗺 Top by Borough")
                            .font(BTFont.bodyBold(size: 16))
                            .foregroundStyle(Color.btText)
                            .padding(.horizontal, BTSpacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: BTSpacing.md) {
                                ForEach(viewModel.boroughCards) { card in
                                    BoroughCard(borough: card.borough, posts: card.posts)
                                }
                            }
                            .padding(.horizontal, BTSpacing.lg)
                        }
                    }

                    // Random neighborhoods list
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("🎲 Random Neighborhoods")
                            .font(BTFont.bodyBold(size: 16))
                            .foregroundStyle(Color.btText)
                            .padding(.horizontal, BTSpacing.lg)

                        ForEach(viewModel.neighborhoods) { n in
                            neighborhoodRow(n)
                                .padding(.horizontal, BTSpacing.lg)
                        }
                    }

                    // City-wide feed — LAST, so its "Load more" growth extends the
                    // bottom of the page instead of pushing the sections above away.
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        HStack {
                            Text("🔥 All of NYC")
                                .font(BTFont.bodyBold(size: 16))
                                .foregroundStyle(Color.btText)
                            Spacer()
                        }
                        .padding(.horizontal, BTSpacing.lg)

                        // Sort control (Most Liked / Newest / …) — reloads the feed.
                        SortFilter(sort: $viewModel.sort)
                            .padding(.horizontal, BTSpacing.lg)

                        // The top post gets the featured treatment only when sorted
                        // by "top" (Most Liked); other sorts read as a flat list.
                        if viewModel.sort == .mostLiked, let topPost = viewModel.trendingPosts.first {
                            NavigationLink(value: topPost) {
                                TrendingCard(post: topPost)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, BTSpacing.lg)

                            LazyVStack(spacing: 0) {
                                ForEach(Array(viewModel.trendingPosts.dropFirst())) { post in
                                    postRow(post)
                                }
                            }
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.trendingPosts) { post in
                                    postRow(post)
                                }
                            }
                        }

                        // Load more — appends the next page at the very bottom.
                        if viewModel.canLoadMore {
                            Button {
                                Task {
                                    await viewModel.loadMore()
                                    await pinStore.ensureLoaded(for: viewModel.trendingPosts)
                                }
                            } label: {
                                HStack(spacing: BTSpacing.sm) {
                                    if viewModel.isLoadingMore {
                                        ProgressView().tint(Color.btText3)
                                    } else {
                                        Text("Load more")
                                            .font(BTFont.bodySemibold(size: 14))
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                }
                                .foregroundStyle(Color.btText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BTSpacing.md)
                                .background(Color.btSurface)
                                .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoadingMore)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, BTSpacing.sm)
                        }
                    }
                    }

                    Spacer(minLength: BTSpacing.xxxl)
                }
            }
            .background(Color.btBg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSearch) {
                SearchView(scope: .global)
            }
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .task {
                await viewModel.load()
                await pinStore.ensureLoaded(for: viewModel.trendingPosts)
            }
            // Changing the sort re-fetches just the city-wide feed.
            .onChange(of: viewModel.sort) {
                Task {
                    await viewModel.reloadTrending()
                    await pinStore.ensureLoaded(for: viewModel.trendingPosts)
                }
            }
        }
    }

    /// One post in the city-wide feed — tappable into its detail.
    private func postRow(_ post: Post) -> some View {
        Group {
            NavigationLink(value: post) {
                PostCard(post: post)
            }
            .buttonStyle(.plain)
            Divider().background(Color.btLine)
        }
    }

    private func neighborhoodRow(_ n: DiscoverNeighborhood) -> some View {
        Button {
            openNeighborhoodFeed(n)
        } label: {
            HStack(spacing: BTSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(n.name)
                        .font(BTFont.bodySemibold(size: 15))
                        .foregroundStyle(Color.btText)
                    Text(n.borough.uppercased())
                        .font(BTFont.monoBold(size: 9))
                        .tracking(0.5)
                        .foregroundStyle(Color.btText3)
                }
                Spacer()
                Text("EXPLORE →")
                    .font(BTFont.bodySemibold(size: 12))
                    .foregroundStyle(Color.btLime)
            }
            .padding(BTSpacing.md)
            .background(Color.btSurface)
            .cornerRadius(BTRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(Color.btLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// Open this neighborhood's feed on the Feed tab.
    private func openNeighborhoodFeed(_ n: DiscoverNeighborhood) {
        if let cached = neighborhoodCache.neighborhood(named: n.name) {
            appState.viewingNeighborhood = cached
        } else {
            let entry = NeighborhoodDirectory.all.first { $0.name.caseInsensitiveCompare(n.name) == .orderedSame }
            let shortCode = entry?.shortCode ?? String(n.name.prefix(4)).uppercased()
            appState.viewingNeighborhood = Neighborhood(
                id: UUID(), name: n.name, shortCode: shortCode,
                borough: entry?.borough ?? n.borough.capitalized
            )
        }
        appState.selectedTab = 0
    }
}

#Preview {
    DiscoverView()
        .environment(AppState())
        .environment(NeighborhoodCache())
        .environment(EnrollmentStore())
        .preferredColorScheme(.dark)
}
