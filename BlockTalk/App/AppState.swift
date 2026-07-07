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

    /// In-progress compose text, stashed so it survives the compose→map→compose
    /// pin-placement round-trip (§13)
    var composeDraft = ""
    /// Signal the Map to auto-enter drop mode (set when compose switches to pin mode)
    var pendingPinPlacement = false

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

/// Session-scoped moderation state (mock mechanics — see HANDOFF for the
/// backend-vs-client seam). Currently drives the reporter-side hide: reporting
/// a post collapses it to a tombstone for you, with a Show-anyway reveal.
@Observable
final class ModerationStore {
    /// postId → reason short string, for posts the current user reported
    private(set) var reportedReasons: [UUID: String] = [:]
    /// posts the reporter chose to reveal despite reporting
    private(set) var shownAnyway: Set<UUID> = []

    func report(postId: UUID, reasonShort: String) {
        reportedReasons[postId] = reasonShort
    }

    func toggleShowAnyway(_ postId: UUID) {
        if shownAnyway.contains(postId) {
            shownAnyway.remove(postId)
        } else {
            shownAnyway.insert(postId)
        }
    }

    func isReported(_ postId: UUID) -> Bool { reportedReasons[postId] != nil }
    func reasonShort(_ postId: UUID) -> String? { reportedReasons[postId] }
    /// Hidden = reported and not currently revealed
    func isHidden(_ postId: UUID) -> Bool { isReported(postId) && !shownAnyway.contains(postId) }
}
