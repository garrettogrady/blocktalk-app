import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(NotificationStore.self) private var store
    @State private var isLoading = false
    /// Shown when a tapped notification's post can't be opened (deleted, or someone
    /// else's since-removed post).
    @State private var unavailableMessage: String?

    private var notifications: [BTNotification] { store.items }

    var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty && !isLoading {
                    emptyState
                } else {
                    List {
                        ForEach(notifications) { notification in
                            // A row tap (not a Button) — a Button label inside a List
                            // renders its Text underlined/tinted; a plain row + tap
                            // gesture keeps the copy clean.
                            notificationRow(notification)
                                .onTapGesture { open(notification) }
                                .listRowBackground(
                                    notification.unread
                                        ? Color.btSurface2 : Color.btBg
                                )
                                .listRowSeparatorTint(Color.btLine)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.btBg)
            .alert("Post unavailable", isPresented: Binding(
                get: { unavailableMessage != nil },
                set: { if !$0 { unavailableMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(unavailableMessage ?? "")
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Mark all read") {
                        markAllRead()
                    }
                    .font(BTFont.body(size: 14))
                    .foregroundStyle(Color.btLime)
                }
            }
        }
    }

    // MARK: - Notification Row

    private func notificationRow(_ notification: BTNotification) -> some View {
        HStack(alignment: .top, spacing: BTSpacing.md) {
            // Unread indicator
            if notification.unread {
                Circle()
                    .fill(Color.btLime)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            } else {
                Spacer().frame(width: 8)
            }

            // Icon based on kind
            notificationIcon(notification.kind)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(notification.title)
                    .font(BTFont.bodySemibold(size: 14))
                    .foregroundStyle(Color.btText)

                if let preview = notification.preview {
                    Text(preview)
                        .font(BTFont.body(size: 13))
                        .foregroundStyle(Color.btText2)
                        .lineLimit(2)
                }

                if let createdAt = notification.createdAt {
                    Text(timeAgo(createdAt))
                        .font(BTFont.body(size: 11))
                        .foregroundStyle(Color.btText3)
                }
            }

            Spacer()

            // Only notifications tied to a post can be opened.
            if notification.relatedPostId != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.btText3)
                    .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, BTSpacing.xs)
    }

    @ViewBuilder
    private func notificationIcon(_ kind: String) -> some View {
        switch kind {
        case "reply":
            Image(systemName: "arrowshape.turn.up.left.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.btLime)
        case "vote":
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.btLime)
        case "moderation":
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.btWarn)
        default:
            Image(systemName: "bell.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.btText3)
        }
    }

    private var emptyState: some View {
        VStack(spacing: BTSpacing.lg) {
            Image(systemName: "bell.slash")
                .font(.system(size: 36))
                .foregroundStyle(Color.btText3)
            Text("No notifications yet")
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Tapping a notification marks it read and opens the post it's about (deep
    /// drop) via the same SharedPostView cover the push path uses.
    private func open(_ notification: BTNotification) {
        // Mark read immediately (local) + persist.
        if notification.unread {
            store.markRead(id: notification.id)
            Task { try? await NotificationService().markRead(id: notification.id) }
        }
        // Some notifications (e.g. generic announcements) have no post to open.
        guard let postId = notification.relatedPostId else { return }
        Task { @MainActor in
            guard let post = try? await PostService().fetchPost(id: postId) else {
                // Couldn't load — the post was deleted, or it's someone else's post
                // that's since been removed (RLS hides it).
                unavailableMessage = "This post is no longer available."
                return
            }
            // Option B: your OWN removed/under-review post opens to its moderation
            // notice (so you learn what happened); someone else's removed post just
            // reads "no longer available" rather than surfacing a dead post.
            if post.status != .live && post.userId != appState.currentUser?.id {
                unavailableMessage = "This post is no longer available."
                return
            }
            // Close this sheet first, then present the post over the You tab so
            // dismissing the post returns cleanly to the tab (not a stacked sheet).
            dismiss()
            try? await Task.sleep(for: .milliseconds(350))
            appState.deepLinkedPost = post
        }
    }

    private func markAllRead() {
        store.markAllRead()   // instant local update
        // Persist so they stay read after relaunch (was memory-only before).
        if let userId = appState.currentUser?.id {
            Task { try? await NotificationService().markAllRead(userId: userId) }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }
}

#Preview {
    NotificationsView()
        .preferredColorScheme(.dark)
}
