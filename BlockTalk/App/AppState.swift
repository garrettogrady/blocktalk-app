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

    /// The neighborhood the user is PHYSICALLY in — the only place they can post
    /// or reply. Mock: set to their home block. [PROD-DIFF: resolve from live GPS.]
    var physicalNeighborhood: Neighborhood?

    /// True when the feed they're viewing is the one they're physically in — the
    /// only case where posting is allowed.
    var canPostInViewing: Bool {
        guard let p = physicalNeighborhood, let v = viewingNeighborhood else { return false }
        return p.name.caseInsensitiveCompare(v.name) == .orderedSame
    }
    /// Whether the initial neighborhood has been resolved (prevents resetting on tab switch)
    var hasResolvedInitialNeighborhood = false
    /// Selected tab index for cross-tab navigation
    var selectedTab = 0

    /// In-progress compose text, stashed so it survives the compose→map→compose
    /// pin-placement round-trip (§13)
    var composeDraft = ""
    /// Signal the Map to auto-enter drop mode (set when compose switches to pin mode)
    var pendingPinPlacement = false

    /// Debug: force the splash to lead into onboarding (bypasses the
    /// returning-user skip) so "Replay onboarding" can show the full flow.
    var forceOnboarding = false

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
        physicalNeighborhood = nil
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

/// Session-scoped offline queue (mock mechanics). Posts made offline queue
/// locally; after a grace window they discard; going online flushes them.
/// [PROD-DIFF: 30s grace → 60min; debug toggle → NWPathMonitor; flushed posts
/// are shown locally, not actually sent — Garrett wires the real send.]
@Observable
final class OfflineStore {
    var isOffline = false
    private(set) var pending: [QueuedPost] = []
    private(set) var discarded: [QueuedPost] = []
    /// Pendings that were flushed on reconnect — shown at the top of the feed
    private(set) var flushed: [Post] = []

    /// 30 seconds for demoability (PROD: 60 minutes)
    static let graceSeconds: TimeInterval = 30

    struct QueuedPost: Identifiable {
        let id = UUID()
        let post: Post
        let queuedAt: Date
    }

    func toggleOffline() {
        isOffline.toggle()
        if !isOffline {
            // Going back online: pendings "send" and promote to normal posts
            flushed.insert(contentsOf: pending.map(\.post), at: 0)
            pending = []
        }
    }

    func enqueue(_ post: Post) {
        pending.insert(QueuedPost(post: post, queuedAt: Date()), at: 0)
    }

    /// Move any pending older than the grace window to discarded. Runs on a
    /// timer regardless of connectivity.
    func expireStale() {
        guard !pending.isEmpty else { return }
        let now = Date()
        let stale = pending.filter { now.timeIntervalSince($0.queuedAt) >= Self.graceSeconds }
        guard !stale.isEmpty else { return }
        discarded.insert(contentsOf: stale, at: 0)
        pending.removeAll { p in stale.contains { $0.id == p.id } }
    }

    func forceExpire() {
        discarded.insert(contentsOf: pending, at: 0)
        pending = []
    }

    func dismissDiscarded(_ id: UUID) {
        discarded.removeAll { $0.id == id }
    }

    func reset() {
        isOffline = false
        pending = []
        discarded = []
        flushed = []
    }
}
