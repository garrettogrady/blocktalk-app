import SwiftUI

struct TrendingCard: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // TOP TRENDING chip
            Text("TOP TRENDING")
                .font(BTFont.monoBold(size: 10))
                .foregroundStyle(Color.btBg)
                .padding(.horizontal, BTSpacing.sm)
                .padding(.vertical, BTSpacing.xs)
                .background(Color.btBg.opacity(0.2))
                .cornerRadius(BTRadius.sm)

            // Post text
            Text(post.text)
                .font(BTFont.bodySemibold(size: 16))
                .foregroundStyle(Color.btBg)
                .lineSpacing(4)
                .lineLimit(3)

            // Stats row
            HStack(spacing: BTSpacing.lg) {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(post.score)")
                        .font(BTFont.mono(size: 12))
                }
                .foregroundStyle(Color.btBg.opacity(0.7))

                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 11))
                    Text("\(post.replyCount)")
                        .font(BTFont.mono(size: 12))
                }
                .foregroundStyle(Color.btBg.opacity(0.7))

                Spacer()
            }
        }
        .padding(BTSpacing.lg)
        .background(Color.btLime)
        .cornerRadius(BTRadius.lg)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        TrendingCard(
            post: Post(
                id: UUID(),
                userId: UUID(),
                neighborhoodId: UUID(),
                text: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter. no regrets.",
                isDailyPrompt: false,
                score: 142,
                replyCount: 38,
                reportCount: 0,
                status: .live
            )
        )
        .padding()
    }
}
