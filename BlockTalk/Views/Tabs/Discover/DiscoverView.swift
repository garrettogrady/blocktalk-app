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
                    // Search bar
                    Button {
                        showSearch = true
                    } label: {
                        HStack(spacing: BTSpacing.md) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.btText3)
                            Text("Search posts across NYC...")
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

                    // Trending section
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("TRENDING")
                            .font(BTFont.mono(size: 11))
                            .foregroundStyle(Color.btText3)
                            .padding(.horizontal, BTSpacing.lg)

                        if let topPost = viewModel.trendingPosts.first {
                            TrendingCard(post: topPost)
                                .padding(.horizontal, BTSpacing.lg)
                        }
                    }

                    // Borough cards horizontal scroll
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("BOROUGHS")
                            .font(BTFont.mono(size: 11))
                            .foregroundStyle(Color.btText3)
                            .padding(.horizontal, BTSpacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: BTSpacing.md) {
                                ForEach(boroughs, id: \.self) { borough in
                                    BoroughCard(
                                        borough: borough,
                                        posts: viewModel.boroughPosts[borough] ?? []
                                    )
                                }
                            }
                            .padding(.horizontal, BTSpacing.lg)
                        }
                    }

                    // Random neighborhoods list
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("EXPLORE NEIGHBORHOODS")
                            .font(BTFont.mono(size: 11))
                            .foregroundStyle(Color.btText3)
                            .padding(.horizontal, BTSpacing.lg)

                        ForEach(viewModel.randomNeighborhoods) { neighborhood in
                            neighborhoodRow(neighborhood)
                                .padding(.horizontal, BTSpacing.lg)
                        }
                    }

                    Spacer(minLength: BTSpacing.xxxl)
                }
                .padding(.top, BTSpacing.md)
            }
            .background(Color.btBg)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showSearch) {
                SearchView(scope: .global)
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private func neighborhoodRow(_ neighborhood: Neighborhood) -> some View {
        HStack(spacing: BTSpacing.md) {
            Text(neighborhood.shortCode)
                .font(BTFont.monoBold(size: 12))
                .foregroundStyle(Color.btLime)
                .frame(width: 80, alignment: .leading)

            Text(neighborhood.name)
                .font(BTFont.bodyMedium(size: 15))
                .foregroundStyle(Color.btText)

            Spacer()

            Text(neighborhood.borough)
                .font(BTFont.body(size: 12))
                .foregroundStyle(Color.btText3)

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(Color.btText3)
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.md)
    }
}

#Preview {
    DiscoverView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
