import SwiftUI

@main
struct BlockTalkApp: App {
    @State private var appState = AppState()
    @State private var locationService = LocationService()
    @State private var moderation = ModerationStore()
    @State private var offline = OfflineStore()
    @State private var localContent = LocalContentStore()
    @State private var notifications = NotificationStore()
    @State private var neighborhoodCache = NeighborhoodCache()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.stage {
                case .splash:
                    SplashView()
                case .how:
                    HowItWorksView()
                case .tone:
                    ToneRulesView()
                case .profile:
                    ProfileCreationView()
                case .username:
                    UsernameCreationView()
                case .app:
                    MainTabView()
                }
            }
            .environment(appState)
            .environment(locationService)
            .environment(moderation)
            .environment(offline)
            .environment(localContent)
            .environment(notifications)
            .environment(neighborhoodCache)
            .preferredColorScheme(.dark)
            .fullScreenCover(item: Binding(
                get: { appState.deepLinkedPost },
                set: { appState.deepLinkedPost = $0 }
            )) { post in
                SharedPostView(post: post)
                    .environment(appState)
                    .environment(locationService)
                    .environment(moderation)
                    .environment(offline)
                    .environment(localContent)
                    .environment(neighborhoodCache)
                    .preferredColorScheme(.dark)
            }
            .onOpenURL { url in handleDeepLink(url) }
            .task {
                await restoreSession()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { locationService.checkPermission() }
            }
            .onChange(of: locationService.currentNeighborhood) { old, resolved in
                if let resolved, locationService.permissionState == .granted {
                    appState.physicalNeighborhood = resolved
                    // First GPS fix: also switch the feed to where the user
                    // actually is (overrides the home-neighborhood default).
                    if old == nil {
                        appState.viewingNeighborhood = resolved
                    }
                }
            }
        }
    }

    /// Route an incoming link to the post it points at.
    private func handleDeepLink(_ url: URL) {
        let segments = url.pathComponents.filter { $0 != "/" }
        let idString: String?
        if url.host == "p" {
            idString = segments.first
        } else if let i = segments.firstIndex(of: "p"), i + 1 < segments.count {
            idString = segments[i + 1]
        } else {
            idString = segments.last
        }
        guard let idString, let id = UUID(uuidString: idString) else { return }
        // Check local store first, then fetch from Supabase
        if let post = localContent.post(id: id) {
            appState.deepLinkedPost = post
        } else {
            Task {
                let postService = PostService()
                if let post = try? await postService.fetchPost(id: id) {
                    await MainActor.run {
                        appState.deepLinkedPost = post
                    }
                }
            }
        }
    }

    /// Restore an existing Supabase session on launch. If a session exists,
    /// fetch the user profile and advance to .app. Otherwise stay on .splash.
    private func restoreSession() async {
        // Load the neighborhood cache at startup
        await neighborhoodCache.loadAll()

        do {
            let session = try await supabase.auth.session
            appState.session = session

            // Fetch user profile from users table
            let users: [BlockTalkUser] = try await supabase.from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value

            guard let user = users.first else {
                // Session exists but no profile — new user, stay on splash
                return
            }

            appState.currentUser = user

            // Resolve home neighborhood for initial viewing
            if let homeId = user.homeNeighborhoodId {
                if let home = neighborhoodCache.neighborhood(id: homeId) {
                    appState.homeNeighborhood = home
                    appState.viewingNeighborhood = home
                    appState.physicalNeighborhood = home
                    appState.hasResolvedInitialNeighborhood = true
                } else {
                    // ID not in cache (stale/synthetic UUID) — fetch directly
                    let fetched: [Neighborhood] = (try? await supabase.from("neighborhoods")
                        .select("id, name, short_code, borough")
                        .eq("id", value: homeId.uuidString)
                        .limit(1)
                        .execute()
                        .value) ?? []
                    if let home = fetched.first {
                        appState.homeNeighborhood = home
                        appState.viewingNeighborhood = home
                        appState.physicalNeighborhood = home
                        appState.hasResolvedInitialNeighborhood = true
                    }
                    // If still nil, FeedView.resolveInitialNeighborhood will handle it
                }
            }

            appState.advanceTo(.app)
        } catch {
            // No valid session — stay on splash
        }
    }
}
