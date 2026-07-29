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

            let posts = selectedTab == .created ? createdPosts : interactedPosts

            if posts.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(posts) { post in
                        PostCard(post: post)
                        Divider().background(Color.btLine)
                    }
                }
            }
        }
        .task {
            await loadPosts()
        }
    }

    private struct PostIdRow: Decodable {
        let postId: UUID
        enum CodingKeys: String, CodingKey { case postId = "post_id" }
    }

    private func loadPosts() async {
        guard let userId = appState.currentUser?.id else { return }
        do {
            // User's own posts
            let created: [Post] = try await supabase.from("posts")
                .select(PostService.postSelect)
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "live")
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            createdPosts = created
            createdCount = created.count

            // Posts the user interacted with (voted or replied to)
            let votedRows: [PostIdRow] = try await supabase.from("votes")
                .select("post_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let votedPostIds = votedRows.map(\.postId)

            let repliedRows: [PostIdRow] = try await supabase.from("replies")
                .select("post_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let repliedPostIds = repliedRows.map(\.postId)

            let allInteractedIds = Array(Set(votedPostIds + repliedPostIds))
            if !allInteractedIds.isEmpty {
                let interacted: [Post] = try await supabase.from("posts")
                    .select(PostService.postSelect)
                    .in("id", values: allInteractedIds.map(\.uuidString))
                    .eq("status", value: "live")
                    .order("created_at", ascending: false)
                    .limit(20)
                    .execute()
                    .value
                interactedPosts = interacted
                interactedCount = interacted.count
            }
        } catch {
            print("PersonalBoard: failed to load — \(error)")
        }
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
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        PersonalBoard()
            .padding()
            .environment(AppState())
    }
}
