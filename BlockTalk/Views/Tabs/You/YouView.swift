import SwiftUI

struct YouView: View {
    @Environment(AppState.self) private var appState
    @Environment(OfflineStore.self) private var offline
    @State private var showNotifications = false
    @State private var showSettings = false
    @State private var showFeedback = false
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BTSpacing.xxl) {
                    // Identity strip
                    if let user = appState.currentUser {
                        IdentityStrip(user: user, postCount: 38, replyCount: 142, totalScore: 1847)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, BTSpacing.md)
                    }

                    // Notifications card
                    notificationsCard
                        .padding(.horizontal, BTSpacing.lg)

                    // Personal board
                    PersonalBoard()
                        .padding(.horizontal, BTSpacing.lg)

                    // Footer actions
                    footerActions
                        .padding(.horizontal, BTSpacing.lg)

                    // 🧪 Offline demo debug card
                    offlineDemoCard
                        .padding(.horizontal, BTSpacing.lg)

                    Spacer(minLength: BTSpacing.xxxl)
                }
            }
            .background(Color.btBg)
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
            HStack(spacing: BTSpacing.md) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.btLime)

                Text("Notifications")
                    .font(BTFont.bodyMedium(size: 15))
                    .foregroundStyle(Color.btText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.btText3)
            }
            .padding(BTSpacing.lg)
            .background(Color.btSurface)
            .cornerRadius(BTRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(Color.btLine, lineWidth: 1)
            )
        }
    }

    // MARK: - Footer Actions

    private var footerActions: some View {
        VStack(spacing: 0) {
            footerButton(icon: "gearshape", title: "Settings") {
                showSettings = true
            }
            Divider().background(Color.btLine)

            footerButton(icon: "envelope", title: "Feedback") {
                showFeedback = true
            }
            Divider().background(Color.btLine)

            footerButton(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", isDestructive: true) {
                showSignOutConfirm = true
            }
        }
        .background(Color.btSurface)
        .cornerRadius(BTRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(Color.btLine, lineWidth: 1)
        )
    }

    // MARK: - Offline Demo (debug)

    private var offlineDemoCard: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("🧪 OFFLINE DEMO")
                .font(BTFont.monoBold(size: 11))
                .tracking(1)
                .foregroundStyle(Color.btText3)

            debugButton(
                offline.isOffline ? "Go back online (flushes queue)" : "Toggle offline",
                icon: offline.isOffline ? "wifi" : "wifi.slash",
                tint: offline.isOffline ? .btLime : .btWarn
            ) { offline.toggleOffline() }

            debugButton(
                "Force-expire pending (\(offline.pending.count))",
                icon: "clock.badge.exclamationmark",
                tint: .btPink,
                disabled: offline.pending.isEmpty
            ) { offline.forceExpire() }

            debugButton("Reset offline state", icon: "arrow.counterclockwise", tint: .btText2) {
                offline.reset()
            }

            Text("Posts made offline queue for \(Int(OfflineStore.graceSeconds))s, then discard.")
                .font(BTFont.body(size: 11))
                .foregroundStyle(Color.btText3)
        }
        .padding(BTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }

    private func debugButton(_ title: String, icon: String, tint: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: icon).font(.system(size: 13)).frame(width: 20)
                Text(title).font(BTFont.bodyMedium(size: 14))
                Spacer()
            }
            .foregroundStyle(disabled ? Color.btText3 : tint)
            .padding(.vertical, BTSpacing.xs)
        }
        .disabled(disabled)
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
        .preferredColorScheme(.dark)
}
