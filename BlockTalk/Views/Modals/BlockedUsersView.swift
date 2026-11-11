import SwiftUI

struct BlockedUsersView: View {
    @Environment(AppState.self) private var appState
    @Environment(BlockStore.self) private var blockStore
    @State private var blockedUsers: [BlockedUserRow] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if blockedUsers.isEmpty {
                VStack(spacing: BTSpacing.md) {
                    Image(systemName: "hand.raised.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.btText3)
                    Text("No blocked users")
                        .font(BTFont.bodySemibold(size: 15))
                        .foregroundStyle(Color.btText2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(BTFont.bodySemibold(size: 15))
                                    .foregroundStyle(Color.btText)
                                Text("#\(user.userNumber)")
                                    .font(BTFont.mono(size: 12))
                                    .foregroundStyle(Color.btText3)
                            }
                            Spacer()
                            Button("Unblock") {
                                guard let myId = appState.currentUser?.id else { return }
                                Task {
                                    await blockStore.unblock(blockerId: myId, blockedId: user.id)
                                    blockedUsers.removeAll { $0.id == user.id }
                                }
                            }
                            .font(BTFont.bodySemibold(size: 13))
                            .foregroundStyle(Color.btLime)
                        }
                    }
                    .listRowBackground(Color.btSurface)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.btBg.ignoresSafeArea())
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadBlockedUsers() }
    }

    private func loadBlockedUsers() async {
        guard let myId = appState.currentUser?.id else {
            isLoading = false
            return
        }
        struct Row: Decodable {
            let blocked_id: UUID
            let blocked: BlockedUser
            struct BlockedUser: Decodable {
                let username: String
                let user_number: Int
            }
        }
        do {
            let rows: [Row] = try await supabase.from("user_blocks")
                .select("blocked_id, blocked:users!user_blocks_blocked_id_fkey(username, user_number)")
                .eq("blocker_id", value: myId.uuidString)
                .execute()
                .value
            blockedUsers = rows.map {
                BlockedUserRow(id: $0.blocked_id, username: $0.blocked.username, userNumber: $0.blocked.user_number)
            }
        } catch {
            print("Failed to load blocked users: \(error)")
        }
        isLoading = false
    }
}

private struct BlockedUserRow: Identifiable {
    let id: UUID
    let username: String
    let userNumber: Int
}
