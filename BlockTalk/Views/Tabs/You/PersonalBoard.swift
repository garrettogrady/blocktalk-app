import SwiftUI

struct PersonalBoard: View {
    @Environment(AppState.self) private var appState

    enum BoardTab: String, CaseIterable {
        case created = "Created"
        case interacted = "Interacted With"

        var count: Int { self == .created ? 38 : 204 }
    }

    @State private var selectedTab: BoardTab = .created
    @State private var createdPosts: [Post] = []
    @State private var interactedPosts: [Post] = []

    var body: some View {
        VStack(spacing: BTSpacing.lg) {
            // Segmented control
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
                            Text("\(tab.count)")
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

            // Post list
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
        .onAppear {
            // Bundled mock — counts (38/204) intentionally exceed visible posts (3/2)
            if createdPosts.isEmpty {
                createdPosts = Array(Post.sampleFeed.prefix(3))
                interactedPosts = Array(Post.sampleFeed.dropFirst(8).prefix(2))
            }
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
