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
                case .profile:
                    ProfileCreationView()
                case .tone:
                    ToneRulesView()
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

    /// Bundled-mock boot: no auth/backend — drop straight into a populated app
    /// with the sample user + LES. (Onboarding is still reachable via Sign Out.)
    private func bootstrapMock() {
        if appState.currentUser == nil {
            appState.currentUser = .sample
            appState.viewingNeighborhood = .les
            appState.physicalNeighborhood = .les   // mock: you're home in LES
            appState.hasResolvedInitialNeighborhood = true
            appState.stage = .app
        }
    }
}
