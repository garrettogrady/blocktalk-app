import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [BTNotification] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty && !isLoading {
                    emptyState
                } else {
                    List {
                        ForEach(notifications) { notification in
                            notificationRow(notification)
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
        }
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

    private func markAllRead() {
        for index in notifications.indices {
            notifications[index].unread = false
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
