import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(NotificationStore.self) private var notifications

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            Tab("Feed", systemImage: "house.fill", value: 0) {
                FeedView()
            }

            Tab("Map", systemImage: "map.fill", value: 1) {
                MapTabView()
            }

            Tab("Discover", systemImage: "magnifyingglass", value: 2) {
                DiscoverView()
            }

            Tab("You", systemImage: "person.fill", value: 3) {
                YouView()
            }
            .badge(notifications.unreadCount)
        }
        .tint(Color.btLime)
        .toolbarBackground(Color.btBg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
