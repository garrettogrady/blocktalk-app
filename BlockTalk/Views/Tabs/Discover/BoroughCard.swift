import SwiftUI

struct BoroughCard: View {
    let borough: String
    let posts: [Post]

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Borough name
            Text(borough.uppercased())
                .font(BTFont.monoBold(size: 13))
                .foregroundStyle(Color.btText)

            // 3 mini-posts stacked
            VStack(spacing: BTSpacing.sm) {
                ForEach(Array(posts.prefix(3))) { post in
                    miniPostRow(post)
                }

                // Placeholder rows if fewer than 3 posts
                if posts.count < 3 {
                    ForEach(0 ..< (3 - posts.count), id: \.self) { _ in
                        placeholderRow
                    }
                }
            }
        }
        .padding(BTSpacing.lg)
        .frame(width: 220)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.lg)
                .stroke(Color.btLine, lineWidth: 1)
        )
    }

    private func miniPostRow(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            Text(post.text)
                .font(BTFont.body(size: 12))
                .foregroundStyle(Color.btText2)
                .lineLimit(2)
                .lineSpacing(2)

            HStack(spacing: BTSpacing.sm) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8, weight: .semibold))
                    Text("\(post.score)")
                        .font(BTFont.mono(size: 9))
                }
                .foregroundStyle(Color.btText3)

                HStack(spacing: 2) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 8))
                    Text("\(post.replyCount)")
                        .font(BTFont.mono(size: 9))
                }
                .foregroundStyle(Color.btText3)

                Spacer()
            }
        }
        .padding(BTSpacing.sm)
        .background(Color.btSurface2)
        .cornerRadius(BTRadius.sm)
    }

    private var placeholderRow: some View {
        RoundedRectangle(cornerRadius: BTRadius.sm)
            .fill(Color.btSurface2)
            .frame(height: 44)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        BoroughCard(borough: "Manhattan", posts: [])
            .padding()
    }
}
