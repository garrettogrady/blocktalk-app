import SwiftUI

struct DiscoverView: View {
    @Environment(AppState.self) private var appState
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

                    // Trending section
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("🔥 Trending in NYC")
                            .font(BTFont.bodyBold(size: 16))
                            .foregroundStyle(Color.btText)
                            .padding(.horizontal, BTSpacing.lg)

                        if let topPost = viewModel.trendingPosts.first {
                            TrendingCard(post: topPost)
                                .padding(.horizontal, BTSpacing.lg)
                        }

                        // #2–10 as regular post cards
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.trendingPosts.dropFirst())) { post in
                                NavigationLink(value: post) {
                                    PostCard(post: post)
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.btLine)
                            }
                        }
                    }

                    // Borough cards horizontal scroll
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
            }
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
                    Text("\(n.borough) · \(n.talking) TALKING")
                        .font(BTFont.monoBold(size: 9))
                        .tracking(0.5)
                        .foregroundStyle(Color.btText3)
                }
                Spacer()
                Text("OPEN →")
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
        let entry = NeighborhoodDirectory.all.first { $0.name.caseInsensitiveCompare(n.name) == .orderedSame }
        let shortCode = entry?.shortCode ?? String(n.name.prefix(4)).uppercased()
        appState.viewingNeighborhood = Neighborhood(
            id: UUID(), name: n.name, shortCode: shortCode,
            borough: entry?.borough ?? n.borough.capitalized
        )
        appState.selectedTab = 0
    }
}

#Preview {
    DiscoverView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
