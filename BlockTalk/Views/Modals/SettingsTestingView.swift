#if DEBUG
import SwiftUI

struct SettingsTestingView: View {
    @Environment(AppState.self) private var appState
    @Environment(ModerationStore.self) private var moderation
    @Environment(OfflineStore.self) private var offline
    @Environment(LocalContentStore.self) private var localContent
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        List {
            Section {
                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delete User & Reset Onboarding")
                                .font(BTFont.bodyMedium(size: 15))
                                .foregroundStyle(Color.btPink)
                            Text("Removes your row from users table, signs out, and returns to splash.")
                                .font(BTFont.body(size: 12))
                                .foregroundStyle(Color.btText3)
                        }
                        Spacer()
                        if isDeleting {
                            ProgressView().tint(Color.btPink)
                        } else {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .foregroundStyle(Color.btPink)
                        }
                    }
                }
                .disabled(isDeleting)

                Button {
                    appState.forceOnboarding = true
                    appState.advanceTo(.splash)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Replay Onboarding")
                                .font(BTFont.bodyMedium(size: 15))
                                .foregroundStyle(Color.btWarn)
                            Text("Re-shows the how-it-works flow without deleting anything.")
                                .font(BTFont.body(size: 12))
                                .foregroundStyle(Color.btText3)
                        }
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(Color.btWarn)
                    }
                }
            } header: {
                Text("ACCOUNT RESET")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            } footer: {
                if let deleteError {
                    Text(deleteError)
                        .font(BTFont.body(size: 12))
                        .foregroundStyle(Color.btPink)
                }
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)

            Section {
                infoRow("User ID", value: appState.session?.user.id.uuidString ?? "none")
                infoRow("Username", value: appState.currentUser?.username ?? "none")
                infoRow("User #", value: appState.currentUser.map { "#\($0.userNumber)" } ?? "none")
                infoRow("Home Hood", value: appState.currentUser?.homeNeighborhoodId?.uuidString.prefix(8).description ?? "none")
                infoRow("Viewing", value: appState.viewingNeighborhood?.name ?? "none")
                infoRow("Physical", value: appState.physicalNeighborhood?.name ?? "none")
                infoRow("Session", value: appState.session != nil ? "active" : "none")
            } header: {
                Text("CURRENT STATE")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.btBg)
        .navigationTitle("Testing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete user and reset?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete & Reset", role: .destructive) {
                performDeleteAndReset()
            }
        } message: {
            Text("This will delete your user row from the database and return you to the splash screen. You'll go through onboarding again on next sign-in.")
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(BTFont.bodyMedium(size: 14))
                .foregroundStyle(Color.btText)
            Spacer()
            Text(value)
                .font(BTFont.mono(size: 11))
                .foregroundStyle(Color.btText3)
                .lineLimit(1)
        }
    }

    private func performDeleteAndReset() {
        guard let userId = appState.session?.user.id else {
            deleteError = "No session — nothing to delete."
            return
        }

        isDeleting = true
        deleteError = nil

        Task {
            do {
                // Use RPC to cascade-delete all user data (bypasses FK constraints
                // and the missing DELETE RLS policy on the users table).
                // Run `Supabase/00003_delete_user_rpc.sql` in the SQL editor first.
                try await supabase.rpc("delete_user_and_data", params: [
                    "p_user_id": userId.uuidString
                ]).execute()

                print("[Testing] User row deleted from database")
            } catch {
                // Log but continue — still sign out and reset locally even if
                // the DB delete fails, so the user can retry onboarding.
                print("[Testing] DB delete failed: \(error)")
                await MainActor.run {
                    deleteError = "DB delete failed (see logs). Signing out anyway."
                }
            }

            do {
                // Sign out with .global scope to clear the local session token
                // cache. Without this, restoreSession() on next launch finds
                // the cached token and auto-logs back in.
                try await supabase.auth.signOut(scope: .global)
                print("[Testing] Signed out (global)")
            } catch {
                print("[Testing] Sign-out failed: \(error)")
            }

            await MainActor.run {
                // Reset all local state
                appState.currentUser = nil
                appState.session = nil
                appState.viewingNeighborhood = nil
                appState.physicalNeighborhood = nil
                appState.hasResolvedInitialNeighborhood = false
                appState.selectedTab = 0
                appState.composeDraft = ""
                appState.pendingPinPlacement = false
                appState.onboardingNeighborhood = nil
                appState.deepLinkedPost = nil
                appState.forceOnboarding = false
                localContent.reset()
                offline.reset()
                appState.stage = .splash
                isDeleting = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsTestingView()
            .environment(AppState())
            .environment(ModerationStore())
            .environment(OfflineStore())
            .environment(LocalContentStore())
    }
    .preferredColorScheme(.dark)
}
#endif
