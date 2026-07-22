import SwiftUI

@main
struct BlockTalkApp: App {
    @State private var appState = AppState()
    @State private var locationService = LocationService()
    @State private var moderation = ModerationStore()
    @State private var offline = OfflineStore()
    @State private var localContent = LocalContentStore()
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
            .preferredColorScheme(.dark)
            // A shared post opens full-screen over everything — read first, then
            // join. This is the highest-intent arrival, so content leads.
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
                    .preferredColorScheme(.dark)
            }
            .onOpenURL { url in handleDeepLink(url) }
            .task {
                bootstrapMock()
            }
            .onChange(of: scenePhase) { _, phase in
                // Recheck permission on foreground so flipping the toggle in
                // iOS Settings clears the gate without a relaunch (§17)
                if phase == .active { locationService.checkPermission() }
            }
            .onChange(of: locationService.currentNeighborhood) { _, resolved in
                // Where you PHYSICALLY are (from GPS) is the postable zone — not
                // the home you picked at onboarding. Once real location resolves,
                // it wins. [PROD-DIFF: server validates presence at submit.]
                if let resolved, locationService.permissionState == .granted {
                    appState.physicalNeighborhood = resolved
                }
            }
        }
    }

    /// Route an incoming link to the post it points at. Handles both the custom
    /// scheme (blocktalk://p/<id>) and the shareable https form
    /// (https://blocktalk.nyc/p/<id>) — same path shape, so one parser covers both.
    /// [PROD: the https form needs an apple-app-site-association file hosted on
    /// blocktalk.nyc to open from Messages; the custom scheme works today.]
    private func handleDeepLink(_ url: URL) {
        let segments = url.pathComponents.filter { $0 != "/" }
        let idString: String?
        if url.host == "p" {                                   // blocktalk://p/<id>
            idString = segments.first
        } else if let i = segments.firstIndex(of: "p"), i + 1 < segments.count {
            idString = segments[i + 1]                          // .../p/<id>
        } else {
            idString = segments.last
        }
        guard let idString, let id = UUID(uuidString: idString),
              let post = Post.find(id: id) ?? localContent.post(id: id) else { return }
        appState.deepLinkedPost = post
    }

    /// Bundled-mock boot: no auth/backend — drop straight into a populated app
    /// with the sample user + LES. (Onboarding is still reachable via Sign Out.)
    private func bootstrapMock() {
        if appState.currentUser == nil {
            appState.currentUser = .sample
            appState.viewingNeighborhood = .les
            appState.physicalNeighborhood = .les   // mock: you're home in LES
            appState.hasResolvedInitialNeighborhood = true
            appState.stage = .app

            // DEMO SEED: one of your posts, removed — so the report/appeal flow is
            // reachable from the feed (removed tombstone → Appeal → form). Delete
            // this block to take it out of the demo.
            localContent.add(post: Post(
                id: UUID(), userId: BlockTalkUser.sample.id, neighborhoodId: Post.lesNeighborhoodId,
                text: "this one got taken down. tap appeal to contest it.",
                isDailyPrompt: false, score: 0, replyCount: 0, reportCount: 6,
                status: .removed, createdAt: Date().addingTimeInterval(-1800),
                author: PostAuthor(username: "BlockTalker", userNumber: 4827, home: .init(shortCode: "LES"))
            ))
        }
    }
}
