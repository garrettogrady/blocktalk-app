import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(NotificationStore.self) private var store
    @Environment(LocalContentStore.self) private var localContent
    @State private var isLoading = false
    @State private var openedPost: Post?

    private var notifications: [BTNotification] { store.items }

    var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty && !isLoading {
                    emptyState
                } else {
                    List {
                        ForEach(notifications) { notification in
                            Group {
                                if notification.relatedPostId != nil {
                                    Button { open(notification) } label: {
                                        notificationRow(notification)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    notificationRow(notification)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                notification.unread
                                    ? Color.btSurface2 : Color.btBg
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.btBg)
            .navigationDestination(item: $openedPost) { post in
                PostDetailView(post: post)
            }
            .onChange(of: appState.focusPin?.id) { _, id in
                // "View on map" from a pushed post detail focuses a pin and switches to
                // the Map tab *underneath* this sheet. Dismiss the sheet so the map is
                // revealed — otherwise the post stays on top of the map.
                if id != nil { dismiss() }
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
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: BTSpacing.md) {
                // Icon — vertically centered with the content (mirrors the real vote arrows).
                notificationIcon(notification)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    // Action line — always primary, and the SAME weight across votes,
                    // replies, and moderation notices. Consistency reads cleaner than
                    // promoting reply text while everything without a body gets demoted.
                    Text(notification.title)
                        .font(BTFont.bodySemibold(size: 15))
                        .foregroundStyle(Color.btText)
                        .lineLimit(2)

                    // The reply's comment, when there is one — secondary "what they said" line.
                    if let preview = notification.preview, !preview.isEmpty {
                        Text(preview)
                            .font(BTFont.body(size: 14))
                            .foregroundStyle(Color.btText2)
                            .lineLimit(2)
                    }

                    if let createdAt = notification.createdAt {
                        Text(timeAgo(createdAt))
                            .font(BTFont.body(size: 11))
                            .foregroundStyle(Color.btText3)
                    }
                }

                Spacer(minLength: BTSpacing.sm)

                // Unread → small dot on the right (the row is also tinted); no left column.
                if notification.unread {
                    Circle()
                        .fill(Color.btLime)
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.vertical, BTSpacing.sm)
            .padding(.horizontal, BTSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Our own separator — full-bleed on BOTH edges. (The system separator
            // insets the trailing side, which made the line look longer on the left.)
            Rectangle()
                .fill(Color.btLine)
                .frame(height: 0.5)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func notificationIcon(_ notification: BTNotification) -> some View {
        switch notification.kind {
        case "reply":
            Image(systemName: "arrowshape.turn.up.left.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.btLime)
        case "vote":
            // Mirror the real vote buttons: ▲ green up / ▽ pink down.
            let isDown = notification.title.localizedCaseInsensitiveContains("down")
            Text(isDown ? "▽" : "▲")
                .font(BTFont.bodyBold(size: 15))
                .foregroundStyle(isDown ? Color.btPink : Color.btLime)
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

    /// Tap a notification → mark it read and drop into the related post.
    private func open(_ notification: BTNotification) {
        guard let postId = notification.relatedPostId else { return }
        // Mark just this one read (local + persisted).
        store.markRead(notification.id)
        Task { try? await NotificationService().markRead(id: notification.id) }
        // Resolve the post — local cache first, then fetch — then push it.
        if let post = localContent.post(id: postId) {
            openedPost = post
        } else {
            Task {
                if let post = try? await PostService().fetchPost(id: postId) {
                    await MainActor.run { openedPost = post }
                }
            }
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
