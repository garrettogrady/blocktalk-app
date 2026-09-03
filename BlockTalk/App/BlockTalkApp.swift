import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("[Push] AppDelegate didFinishLaunching")
        print("[Push] isRegisteredForRemoteNotifications = \(application.isRegisteredForRemoteNotifications)")
        // Register immediately
        application.registerForRemoteNotifications()
        // Retry at staggered intervals — some devices need the app fully
        // initialized before iOS will deliver the token callback
        for delay in [1.0, 3.0, 6.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if pushManager.hasToken { return }
                print("[Push] Retry registerForRemoteNotifications (after \(delay)s)")
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[Push] ✅ didRegisterForRemoteNotifications — token length: \(deviceToken.count) bytes")
        pushManager.didRegisterToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Push] ❌ didFailToRegisterForRemoteNotifications: \(error)")
    }
}

@main
struct BlockTalkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @State private var locationService = LocationService()
    @State private var moderation = ModerationStore()
    @State private var offline = OfflineStore()
    @State private var localContent = LocalContentStore()
    @State private var pinStore = PinStore()
    @State private var notifications = NotificationStore()
    @State private var neighborhoodCache = NeighborhoodCache()
    @State private var enrollments = EnrollmentStore()
    /// Drives the cosmetic launch logo overlay ONLY. Never touched by session restore
    /// or any network call — dismissed by a local, hard-capped timer (see body .task),
    /// so it can never trap the app. Starts true so the logo shows the instant we render.
    @State private var showLaunchLogo = true
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
            .environment(pinStore)
            .environment(notifications)
            .environment(neighborhoodCache)
            .environment(enrollments)
            .preferredColorScheme(.dark)
            // Cosmetic launch cover: the block.talk logo on dark, sitting ON TOP of the
            // real landing (which renders underneath the whole time — the known-good
            // setup). This is an overlay, NOT a gate, so it can never stop the app from
            // rendering. If anything ever went wrong, the worst case is the logo lingers
            // a beat — never a black screen.
            .overlay {
                if showLaunchLogo {
                    LoadingSplashView()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.35), value: showLaunchLogo)
            .task {
                // Dismiss the logo with a LOCAL timer that depends on nothing external —
                // no network, no session restore. Fade out as soon as the app has settled
                // into its real stage, or after a hard 2.5s cap, whichever is first.
                for _ in 0..<25 {
                    if appState.stage == .app { break }
                    try? await Task.sleep(for: .milliseconds(100))
                }
                showLaunchLogo = false
            }
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
                    .environment(pinStore)
                    .environment(notifications)
                    .environment(neighborhoodCache)
                    .environment(enrollments)
                    .preferredColorScheme(.dark)
            }
            // A post opened from the user's own notification (in-app row or push tap):
            // the normal thread view, not the "shared with you" card.
            .fullScreenCover(item: Binding(
                get: { appState.openedPost },
                set: { appState.openedPost = $0 }
            )) { post in
                NavigationStack {
                    PostDetailView(post: post)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Done") { appState.openedPost = nil }
                                    .foregroundStyle(Color.btText2)
                            }
                        }
                }
                .environment(appState)
                .environment(locationService)
                .environment(moderation)
                .environment(offline)
                .environment(localContent)
                .environment(pinStore)
                .environment(notifications)
                .environment(neighborhoodCache)
                .environment(enrollments)
                .preferredColorScheme(.dark)
                // "View on map" switches tabs underneath — dismiss so the map is visible.
                .onChange(of: appState.selectedTab) { _, _ in appState.openedPost = nil }
            }
            .onOpenURL { url in handleDeepLink(url) }
            .task {
                UNUserNotificationCenter.current().delegate = pushManager
                pushManager.checkPermission()
                Analytics.setup()
                await restoreSession()
            }
            .onChange(of: appState.stage) { _, stage in
                if stage == .app, let userId = appState.currentUser?.id {
                    pushManager.currentUserId = userId
                    pushManager.checkPermission()
                    pushManager.saveToken(userId: userId)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    locationService.checkPermission()
                    pushManager.checkPermission()
                    Analytics.appOpened()
                    UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
                    // Retry token registration if we still don't have one
                    if !pushManager.hasToken {
                        print("[Push] No token yet on .active — retrying registration")
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .pushNotificationTapped)) { notification in
                if let post = notification.userInfo?["post"] as? Post {
                    // A push about your own post → open the thread, not the share card.
                    appState.openedPost = post
                }
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
            pushManager.currentUserId = user.id
            Analytics.identify(userId: user.id, isSeed: user.isSeed ?? true)

            // Resolve home neighborhood for initial viewing
            if let homeId = user.homeNeighborhoodId {
                if let home = neighborhoodCache.neighborhood(id: homeId) {
                    appState.homeNeighborhood = home
                    appState.viewingNeighborhood = home
                    // Do NOT seed physicalNeighborhood from home — GPS-only (see above).
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
                        // NOTE: do NOT set physicalNeighborhood here. "Physical" means
                        // where you actually are right now, and is set ONLY from a real
                        // GPS fix (see .onChange on locationService.currentNeighborhood).
                        // Seeding it from home let a user post to their home neighborhood
                        // while physically elsewhere (e.g. abroad).
                        appState.hasResolvedInitialNeighborhood = true
                    }
                    // If still nil, FeedView.resolveInitialNeighborhood will handle it
                }
            }

            await enrollments.load(userId: user.id)
            appState.advanceTo(.app)
        } catch {
            // No valid session — stay on splash
        }
    }
}
