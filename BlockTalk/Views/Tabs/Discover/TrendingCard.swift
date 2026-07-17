import SwiftUI

struct TrendingCard: View {
    let post: Post

    @Environment(AppState.self) private var appState
    @Environment(ModerationStore.self) private var moderation
    @State private var enrolled = false
    @State private var showReport = false

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // TOP TRENDING chip
            HStack(spacing: BTSpacing.xs) {
                Image(systemName: "trophy.fill").font(.system(size: 10))
                Text("TOP TRENDING").font(BTFont.monoBold(size: 10)).tracking(1)
            }
            .foregroundStyle(Color.btLime)

            // Meta row
            HStack(spacing: 6) {
                if let a = post.author {
                    Text("@\(a.username ?? "user")")
                        .font(BTFont.bodySemibold(size: 11))
                        .foregroundStyle(Color.btText)
                    Text("#\((a.userNumber ?? 0).formatted(.number))")
                        .font(BTFont.monoBold(size: 11))
                        .foregroundStyle(Color.btLime)
                    if let home = a.home?.shortCode {
                        HomeBadge(shortCode: home)
                    }
                }
                Spacer(minLength: 0)
            }

            // Body
            Text(post.text)
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText)
                .lineSpacing(4)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            // Action row — matches every other post card
            HStack(spacing: 6) {
                VotePills(score: post.score, onUpvote: {}, onDownvote: {})

                actionButton(systemName: enrolled ? "bell.fill" : "bell",
                             active: enrolled, activeColor: .btLime) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    enrolled.toggle()
                }
                actionButton(systemName: "square.and.arrow.up") {
                    ShareHelper.sharePost(post)
                }
                if appState.currentUser?.id != post.userId {
                    if moderation.isReported(post.id) {
                        actionButton(systemName: "flag.fill", active: true, activeColor: .btPink) {}
                    } else {
                        actionButton(systemName: "flag") { showReport = true }
                    }
                }

                Spacer(minLength: 0)

                (Text("\(post.replyCount)").foregroundStyle(Color.btText)
                 + Text(" replies").foregroundStyle(Color.btText2))
                    .font(BTFont.monoBold(size: 11))
            }
        }
        .padding(BTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btLime.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btLime.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        .sheet(isPresented: $showReport) {
            ReportModalView(postId: post.id) { short in
                moderation.report(postId: post.id, reasonShort: short)
            }
        }
    }

    private func actionButton(systemName: String, active: Bool = false, activeColor: Color = .btText2, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(active ? activeColor : Color.btText2)
                .frame(width: 30, height: 30)
                .background(active ? activeColor.opacity(0.12) : Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.sm)
                        .stroke(active ? activeColor.opacity(0.45) : Color.btLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        TrendingCard(
            post: Post(
                id: UUID(), userId: UUID(), neighborhoodId: UUID(),
                text: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter. no regrets.",
                isDailyPrompt: false, score: 142, replyCount: 38, reportCount: 0, status: .live,
                author: PostAuthor(username: "streetrat", userNumber: 4827, home: .init(shortCode: "LES"))
            )
        )
        .environment(AppState())
        .environment(ModerationStore())
        .padding()
    }
}
