import SwiftUI

struct TrendingCard: View {
    let post: Post

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

            // Vote pills + reply count
            HStack(spacing: BTSpacing.sm) {
                VotePills(score: post.score, onUpvote: {}, onDownvote: {})
                Spacer()
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
