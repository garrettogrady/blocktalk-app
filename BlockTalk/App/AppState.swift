import Foundation
import SwiftUI
import Supabase

enum AppStage {
    case splash
    case how
    case tone
    case profile     // step 1: home neighborhood
    case username    // step 2: username (forced choice)
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

    /// The user's HOME neighborhood (resolved at launch) — drives the 🏠 identity
    /// badge. Distinct from viewing, which changes as you browse.
    var homeNeighborhood: Neighborhood?

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

    /// The neighborhood picked on onboarding step 1, carried to step 2 (username)
    /// so the final profile can be assembled once both are chosen.
    var onboardingNeighborhood: Neighborhood?

    /// A post opened via a shared link (blocktalk://p/<id>). When set, it's
    /// presented full-screen over whatever's on screen — so a recipient reads
    /// the post that hooked them before (or instead of) onboarding.
    var deepLinkedPost: Post?

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
    /// posts whose removal the user has already appealed (one appeal per post)
    private(set) var appealedPostIds: Set<UUID> = []

    func report(postId: UUID, reasonShort: String) {
        reportedReasons[postId] = reasonShort
    }

    func markAppealed(_ postId: UUID) { appealedPostIds.insert(postId) }
    func hasAppealed(_ postId: UUID) -> Bool { appealedPostIds.contains(postId) }

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

/// Session-scoped notifications. Fetches from Supabase on load; report and
/// appeal actions push new ones so they show in the bell + tab badge.
@Observable
final class NotificationStore {
    private(set) var items: [BTNotification] = []

    var unreadCount: Int { items.filter(\.unread).count }

    func load(userId: UUID) async {
        do {
            let fetched: [BTNotification] = try await supabase.from("notifications")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            items = fetched
        } catch {
            print("NotificationStore: failed to load — \(error)")
        }
    }

    func add(kind: String, title: String, preview: String? = nil, relatedPostId: UUID? = nil) {
        let note = BTNotification(id: UUID(), userId: UUID(), kind: kind, title: title,
                                  preview: preview, unread: true,
                                  relatedPostId: relatedPostId, createdAt: Date())
        items.insert(note, at: 0)
    }

    func markAllRead() {
        for i in items.indices { items[i].unread = false }
    }
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

/// Session-scoped store for content the user creates in this run (posts + pins).
/// The mock has no backend, so a new post/street-comment lives here and is
/// merged into the feed + map for the session. [PROD-DIFF: Garrett's Supabase
/// writes replace this — createPost/createPin insert server-side instead.]
@Observable
final class LocalContentStore {
    private(set) var posts: [Post] = []   // newest first
    private(set) var pins: [Pin] = []
    private(set) var repliesByPost: [UUID: [Reply]] = [:]   // postId → replies you sent

    /// Add a freshly-created post (and its pin, for a street comment).
    func add(post: Post, pin: Pin? = nil) {
        if let pin { pins.insert(pin, at: 0) }
        posts.insert(post, at: 0)
    }

    /// Persist a reply so it survives leaving + reopening the post this session.
    func addReply(_ reply: Reply, toPost postId: UUID) {
        repliesByPost[postId, default: []].append(reply)
    }

    func replies(forPost postId: UUID) -> [Reply] {
        repliesByPost[postId] ?? []
    }

    /// User-created posts for a given neighborhood, newest first.
    func posts(in neighborhoodId: UUID) -> [Post] {
        posts.filter { $0.neighborhoodId == neighborhoodId }
    }

    func pin(id: UUID) -> Pin? { pins.first { $0.id == id } }
    func post(forPinId pinId: UUID) -> Post? { posts.first { $0.pinId == pinId } }
    func post(id: UUID) -> Post? { posts.first { $0.id == id } }

    func reset() {
        posts = []
        pins = []
        repliesByPost = [:]
    }
}
