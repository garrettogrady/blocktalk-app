import SwiftUI

struct YouView: View {
    @Environment(AppState.self) private var appState
    @Environment(OfflineStore.self) private var offline
    @Environment(NotificationStore.self) private var notifications
    @State private var showNotifications = false
    @State private var showSettings = false
    @State private var showFeedback = false
    @State private var showSignOutConfirm = false
    @State private var postCount = 0
    @State private var replyCount = 0
    @State private var totalScore = 0
    @State private var downvoteCount = 0
    /// Level to celebrate with the one-time banner, if any.
    @State private var pendingLevelUp: AuthorityLevel?

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            ScrollView {
                VStack(spacing: BTSpacing.xxl) {
                    // One-time level-up banner (shown once per level, above the identity card)
                    if let level = pendingLevelUp {
                        LevelUpBanner(level: level) {
                            if let user = appState.currentUser, let aura = user.aura {
                                LevelUpTracker.markSeen(userId: user.id, aura: aura)
                            }
                            withAnimation { pendingLevelUp = nil }
                        }
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.top, BTSpacing.md)
                        .transition(.opacity)
                    }

                    // Identity strip
                    if let user = appState.currentUser {
                        IdentityStrip(user: user, postCount: postCount, replyCount: replyCount,
                                      totalScore: totalScore, downvoteCount: downvoteCount,
                                      homeShortCode: appState.homeNeighborhood?.shortCode)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, pendingLevelUp == nil ? BTSpacing.md : 0)

                        // Authority card (tier name in display type, progress, levels left)
                        if let aura = user.aura {
                            AuthorityCard(aura: aura) { appState.showAuthorityPage = true }
                                .padding(.horizontal, BTSpacing.lg)
                        }
                    }

                    // Settings + Feedback — visible on landing (not buried under
                    // the Personal Board scroll)
                    quickActionsRow
                        .padding(.horizontal, BTSpacing.lg)

                    // Notifications card
                    notificationsCard
                        .padding(.horizontal, BTSpacing.lg)

                    // Personal board — posts run full-width like the Feed (the board
                    // pads its own header/empty state); don't wrap it in horizontal padding.
                    PersonalBoard()

                    // Sign out (bottom — destructive, away from the primary actions)
                    signOutRow
                        .padding(.horizontal, BTSpacing.lg)

                    Spacer(minLength: BTSpacing.xxxl)
                }
            }
            .background(Color.btBg)
            .toolbar(.hidden, for: .navigationBar)
            // Personal Board rows push Post Detail onto THIS stack, so the
            // detail's back button returns to the You tab.
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .navigationDestination(isPresented: $appState.showAuthorityPage) {
                AuthorityView()
            }
            // onAppear so stats + notifications also refresh when you return to
            // the tab (e.g. after posting), not just on first launch.
            .onAppear {
                Task {
                    await loadStats()
                    await refreshAura()
                    if let userId = appState.currentUser?.id {
                        await notifications.load(userId: userId)
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsHubView()
                }
            }
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
            }
            .alert("Sign out of BlockTalk?", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { appState.signOut() }
            } message: {
                Text("You'll need to sign back in with Apple to continue.")
            }
        }
    }

    // MARK: - Notifications Card

    private var notificationsCard: some View {
        Button {
            showNotifications = true
        } label: {
            VStack(alignment: .leading, spacing: BTSpacing.md) {
                HStack(spacing: BTSpacing.sm) {
                    Text("📬 NOTIFICATIONS")
                        .font(BTFont.monoBold(size: 10))
                        .tracking(1)
                        .foregroundStyle(Color.btText3)
                    if notifications.unreadCount > 0 {
                        Text("\(notifications.unreadCount) NEW")
                            .font(BTFont.monoBold(size: 9))
                            .foregroundStyle(Color.btOnAccent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.btPink).clipShape(Capsule())
                    }
                    Spacer()
                }

                if notifications.items.isEmpty {
                    Text("No notifications yet — you'll hear when someone replies or votes.")
                        .font(BTFont.body(size: 13))
                        .foregroundStyle(Color.btText3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(notifications.items.prefix(2)) { notif in
                        HStack(alignment: .top, spacing: BTSpacing.sm) {
                            Circle()
                                .fill(notif.unread ? Color.btLime : Color.clear)
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(notif.title)
                                    .font(BTFont.bodySemibold(size: 13))
                                    .foregroundStyle(Color.btText)
                                    .lineLimit(1)
                                if let p = notif.preview {
                                    Text(p)
                                        .font(BTFont.body(size: 12))
                                        .foregroundStyle(Color.btText2)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                    }

                    Text("VIEW ALL (\(notifications.items.count)) →")
                        .font(BTFont.bodySemibold(size: 12))
                        .foregroundStyle(Color.btLime)
                }
            }
            .padding(BTSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.btSurface)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(Color.btLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick actions (Settings + Feedback) — on landing

    private var quickActionsRow: some View {
        HStack(spacing: BTSpacing.md) {
            quickAction(icon: "gearshape", title: "Settings") { showSettings = true }
            quickAction(icon: "envelope", title: "Feedback") { showFeedback = true }
        }
    }

    private func quickAction(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: icon).font(.system(size: 15)).foregroundStyle(Color.btText2)
                Text(title).font(BTFont.bodyMedium(size: 15)).foregroundStyle(Color.btText)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(Color.btText3)
            }
            .padding(BTSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(Color.btSurface)
            .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func loadStats() async {
        guard let userId = appState.currentUser?.id else { return }
        do {
            struct StatsResult: Decodable {
                let postCount: Int
                let replyCount: Int
                let totalScore: Int
                let downvoteCount: Int
                enum CodingKeys: String, CodingKey {
                    case postCount = "post_count"
                    case replyCount = "reply_count"
                    case totalScore = "total_score"
                    case downvoteCount = "downvote_count"
                }
            }
            let results: [StatsResult] = try await supabase.rpc(
                "user_stats",
                params: ["p_user_id": userId.uuidString]
            ).execute().value
            if let stats = results.first {
                postCount = stats.postCount
                replyCount = stats.replyCount
                totalScore = stats.totalScore
                downvoteCount = stats.downvoteCount
            }
        } catch {
            print("Failed to load user stats: \(error)")
        }
    }

    /// Refresh the cached aura so the card, banner and own-post badges are current.
    private func refreshAura() async {
        guard let userId = appState.currentUser?.id else { return }
        struct Row: Decodable { let aura: Int }
        do {
            let row: Row = try await supabase.from("users")
                .select("aura")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            appState.currentUser?.aura = row.aura
            let due = LevelUpTracker.pendingLevel(userId: userId, aura: row.aura)
            // Don't re-trigger the banner animation on every tab visit.
            if due != pendingLevelUp { pendingLevelUp = due }
        } catch {
            print("Failed to load aura: \(error)")
        }
    }

    private var signOutRow: some View {
        footerButton(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", isDestructive: true) {
            showSignOutConfirm = true
        }
        .background(Color.btSurface)
        .cornerRadius(BTRadius.md)
        .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
    }

    private func footerButton(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BTSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(isDestructive ? Color.btPink : Color.btText2)
                    .frame(width: 24)

                Text(title)
                    .font(BTFont.bodyMedium(size: 15))
                    .foregroundStyle(isDestructive ? Color.btPink : Color.btText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.btText3)
            }
            .padding(BTSpacing.lg)
        }
    }
}

#Preview {
    YouView()
        .environment(AppState())
        .environment(OfflineStore())
        .environment(NotificationStore())
        .preferredColorScheme(.dark)
}
