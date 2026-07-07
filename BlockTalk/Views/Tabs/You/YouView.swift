import SwiftUI

struct YouView: View {
    @Environment(AppState.self) private var appState
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
                        IdentityStrip(user: user)
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
