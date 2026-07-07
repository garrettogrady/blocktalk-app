import SwiftUI

@main
struct BlockTalkApp: App {
    @State private var appState = AppState()
    @State private var locationService = LocationService()
    @State private var moderation = ModerationStore()
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
            .preferredColorScheme(.dark)
            .task {
                await restoreSession()
            }
            .onChange(of: scenePhase) { _, phase in
                // Recheck permission on foreground so flipping the toggle in
                // iOS Settings clears the gate without a relaunch (§17)
                if phase == .active { locationService.checkPermission() }
            }
        }
    }

    private func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            appState.session = session

            // Check if user profile exists
            let users: [BlockTalkUser] = try await supabase.from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value

            if let user = users.first {
                appState.currentUser = user
                appState.advanceTo(.app)
            }
            // If no profile yet, stay on splash — user will sign in and go through onboarding
        } catch {
            // No existing session — stay on splash
        }
    }
}
