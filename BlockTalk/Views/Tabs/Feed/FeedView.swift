import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @State private var viewModel = FeedViewModel()
    @State private var showCompose = false
    @State private var showNeighborhoodPicker = false
    @State private var showPreFrame = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Location gate banner at top when location not granted
                        LocationGateBanner(showPreFrame: $showPreFrame)

                        // Daily prompt card
                        if let prompt = viewModel.dailyPrompt {
                            DailyPromptCard(prompt: prompt)
                                .padding(.horizontal, BTSpacing.lg)
                                .padding(.top, BTSpacing.md)
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
        }
    }

    // MARK: - Location Row

    private var locationRow: some View {
        Button {
            showNeighborhoodPicker = true
        } label: {
            HStack(spacing: BTSpacing.sm) {
                Text("VIEWING")
                    .font(BTFont.mono(size: 10))
                    .foregroundStyle(Color.btText3)

                Image(systemName: "house.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.btHouse)

                Text(appState.viewingNeighborhood?.name ?? "Locating...")
                    .font(BTFont.display(size: 18))
                    .foregroundStyle(Color.btText)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.btText3)

                Spacer()
            }
            .padding(.vertical, BTSpacing.sm)
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
