import Foundation
import SwiftUI
import Supabase

enum AppStage {
    case splash
    case profile
    case tone
    case app
}

@Observable
final class AppState {
    var stage: AppStage = .splash
    var currentUser: BlockTalkUser?
    var session: Session?
    var isAuthenticated: Bool { session != nil }

    /// The neighborhood the user is currently viewing/interacting with (shared across tabs)
    var viewingNeighborhood: Neighborhood?
    /// Whether the initial neighborhood has been resolved (prevents resetting on tab switch)
    var hasResolvedInitialNeighborhood = false
    /// Selected tab index for cross-tab navigation
    var selectedTab = 0

    func advanceTo(_ stage: AppStage) {
        withAnimation {
            self.stage = stage
        }
    }

    func signOut() {
        Task {
            try? await supabase.auth.signOut()
        }
        currentUser = nil
        session = nil
        viewingNeighborhood = nil
        hasResolvedInitialNeighborhood = false
        selectedTab = 0
        stage = .splash
    }
}
