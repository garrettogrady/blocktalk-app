import SwiftUI

struct PersonalBoard: View {
    @Environment(AppState.self) private var appState

    enum BoardTab: String, CaseIterable {
        case created = "Created"
        case interacted = "Interacted With"
    }

    @State private var selectedTab: BoardTab = .created
    @State private var createdPosts: [Post] = []
    @State private var interactedPosts: [Post] = []
    @State private var createdCount = 0
    @State private var interactedCount = 0
    /// Distinguishes a failed load from a genuinely empty board — otherwise a network
    /// error shows "No posts yet" to a user who actually has posts.
    @State private var loadFailed = false

    var body: some View {
        VStack(spacing: BTSpacing.lg) {
            HStack(spacing: 0) {
                ForEach(BoardTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: BTSpacing.xs) {
                            Text(tab.rawValue)
                                .font(BTFont.bodySemibold(size: 14))
                            Text("\(tab == .created ? createdCount : interactedCount)")
                                .font(BTFont.monoBold(size: 12))
                                .opacity(0.7)
                        }
                        .foregroundStyle(selectedTab == tab ? Color.btOnAccent : Color.btText2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BTSpacing.sm)
                        .background(selectedTab == tab ? Color.btLime : Color.clear)
                        .cornerRadius(BTRadius.sm)
                    }
                }
            }
            .padding(BTSpacing.xs)
            .background(Color.btSurface)
            .cornerRadius(BTRadius.md)
            .padding(.horizontal, BTSpacing.lg)

            let posts = selectedTab == .created ? createdPosts : interactedPosts

            if posts.isEmpty && loadFailed {
                errorState
            } else if posts.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(posts) { post in
                        NavigationLink(value: post) {
                            PostCard(post: post)
                        }
                        .buttonStyle(.plain)
                        Divider().background(Color.btLine)
                    }
                }
            }
        }
        // onAppear (not task) so it also re-fetches when you return to the You tab
        // after posting elsewhere — was stale until relaunch.
        .onAppear {
            Task { await loadPosts() }
        }
    }

    private func loadPosts() async {
        guard let userId = appState.currentUser?.id else { return }
        loadFailed = false
        do {
            // Accurate counts from user_stats RPC
            struct Stats: Decodable {
                let postCount: Int
                enum CodingKeys: String, CodingKey { case postCount = "post_count" }
            }
            let stats: [Stats] = try await supabase.rpc("user_stats", params: ["p_user_id": userId.uuidString])
                .execute()
                .value
            createdCount = stats.first?.postCount ?? 0

            // Created posts via RPC (paginated, no 20-row cap on count)
            let created: [Post] = try await supabase.rpc("user_created_posts", params: [
                "p_user_id": userId.uuidString,
                "p_limit": "50",
                "p_offset": "0",
            ]).execute().value
            // The RPCs return bare post rows; without the author join every card
            // falls back to the "@BlockTalker #0" placeholder.
            createdPosts = try await PostService().attachingAuthors(to: created)

            // Interacted posts via RPC (no URL-length issue)
            let interacted: [Post] = try await supabase.rpc("user_interacted_posts", params: [
                "p_user_id": userId.uuidString,
                "p_limit": "50",
                "p_offset": "0",
            ]).execute().value
            interactedPosts = try await PostService().attachingAuthors(to: interacted)

            // Accurate interacted count via RPC
            let countResult: Int = try await supabase.rpc("user_interacted_count", params: [
                "p_user_id": userId.uuidString,
            ]).execute().value
            interactedCount = countResult
        } catch {
            print("PersonalBoard: failed to load — \(error)")
            loadFailed = true
        }
    }

    private var errorState: some View {
        VStack(spacing: BTSpacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 28))
                .foregroundStyle(Color.btText3)
            Text("Couldn't load your posts.")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText3)
            Button("Try again") {
                Task { await loadPosts() }
            }
            .font(BTFont.bodySemibold(size: 14))
            .foregroundStyle(Color.btLime)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BTSpacing.xxxl)
        .padding(.horizontal, BTSpacing.lg)
    }

    private var emptyState: some View {
        VStack(spacing: BTSpacing.md) {
            Image(systemName: selectedTab == .created ? "square.and.pencil" : "hand.thumbsup")
                .font(.system(size: 28))
                .foregroundStyle(Color.btText3)

            Text(selectedTab == .created
                ? "No posts yet. Share what's on your block!"
                : "No interactions yet. Start voting and replying!")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BTSpacing.xxxl)
        .padding(.horizontal, BTSpacing.lg)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        PersonalBoard()
            .padding()
            .environment(AppState())
            .environment(EnrollmentStore())
    }
}
