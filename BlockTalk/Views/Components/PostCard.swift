import SwiftUI

struct PostCard: View {
    let post: Post
    var isPreview: Bool = false
    var username: String = "BlockTalker"
    var userNumber: Int = 0
    var homeShortCode: String?
    var cornerName: String?

    @Environment(AppState.self) private var appState
    @State private var showReport = false
    @State private var showEnrollmentToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Meta row
            metaRow

            // Body text
            Text(post.text)
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)

            // Optional image
            if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 220)
                            .cornerRadius(BTRadius.md)
                            .clipped()
                    case .failure:
                        EmptyView()
                    default:
                        RoundedRectangle(cornerRadius: BTRadius.md)
                            .fill(Color.btSurface2)
                            .frame(height: 120)
                            .overlay(ProgressView().tint(Color.btText3))
                    }
                }
            }

            // Action row (hidden in preview mode)
            if !isPreview {
                actionRow
            }
        }
        .padding(BTSpacing.lg)
        .background(Color.btBg)
        .overlay(alignment: .leading) {
            // Street comment variant: 3px lime left border
            if post.isStreetComment {
                Rectangle()
                    .fill(Color.btLime)
                    .frame(width: 3)
            }
        }
        .background(
            post.isStreetComment ? Color.btLime.opacity(0.04) : Color.clear
        )
        .sheet(isPresented: $showReport) {
            ReportModalView(postId: post.id)
        }
        .overlay(alignment: .top) {
            if showEnrollmentToast {
                enrollmentToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Meta Row

    private var metaRow: some View {
        HStack(spacing: BTSpacing.sm) {
            Text(username)
                .font(BTFont.bodySemibold(size: 13))
                .foregroundStyle(Color.btText)

            Text("#\(String(format: "%04d", userNumber))")
                .font(BTFont.mono(size: 11))
                .foregroundStyle(Color.btText3)

            // Home badge
            if let shortCode = homeShortCode {
                HomeBadge(shortCode: shortCode)
            }

            // Corner badge for street comments
            if let corner = cornerName ?? post.pinId.map({ _ in "Corner" }) {
                PinBadge(cornerName: corner)
            }

            Spacer()

            // Time ago
            if let createdAt = post.createdAt {
                Text(timeAgo(createdAt))
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            }
        }
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: BTSpacing.lg) {
            // Vote pills
            VotePills(
                score: post.score,
                onUpvote: {
                    // Handle upvote
                },
                onDownvote: {
                    // Handle downvote
                }
            )

            // Bell button
            Button {
                withAnimation {
                    showEnrollmentToast = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation {
                        showEnrollmentToast = false
                    }
                }
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.btText3)
            }

            // Share button
            Button {
                // Share action
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.btText3)
            }

            // Flag button (hidden on own posts)
            if appState.currentUser?.id != post.userId {
                Button {
                    showReport = true
                } label: {
                    Image(systemName: "flag")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.btText3)
                }
            }

            Spacer()

            // Reply count
            HStack(spacing: BTSpacing.xs) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 12))
                Text("\(post.replyCount)")
                    .font(BTFont.mono(size: 12))
            }
            .foregroundStyle(Color.btText3)
        }
    }

    // MARK: - Enrollment Toast

    private var enrollmentToast: some View {
        Text("You'll be notified about this post")
            .font(BTFont.body(size: 13))
            .foregroundStyle(Color.btBg)
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.sm)
            .background(Color.btLime)
            .cornerRadius(BTRadius.full)
            .padding(.top, BTSpacing.sm)
    }

    // MARK: - Time Ago

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
    ZStack {
        Color.btBg.ignoresSafeArea()
        PostCard(
            post: Post(
                id: UUID(),
                userId: UUID(),
                neighborhoodId: UUID(),
                text: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter. no regrets.",
                isDailyPrompt: false,
                score: 42,
                replyCount: 7,
                reportCount: 0,
                status: .live
            ),
            username: "BlockTalker",
            userNumber: 42,
            homeShortCode: "LES"
        )
        .environment(AppState())
    }
}
