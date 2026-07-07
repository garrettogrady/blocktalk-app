import SwiftUI

struct BoroughCard: View {
    let borough: String
    let posts: [BoroughMini]

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text(borough.uppercased())
                .font(BTFont.monoBold(size: 12))
                .tracking(1)
                .foregroundStyle(Color.btLime)

            VStack(spacing: 0) {
                ForEach(Array(posts.enumerated()), id: \.element.id) { i, post in
                    miniPostRow(post)
                    if i < posts.count - 1 {
                        Divider().background(Color.btLine)
                    }
                }
            }
        }
        .padding(BTSpacing.lg)
        .frame(width: 240, alignment: .leading)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.lg)
                .stroke(Color.btLine, lineWidth: 1)
        )
    }

    private func miniPostRow(_ post: BoroughMini) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            Text(post.text)
                .font(BTFont.body(size: 12))
                .foregroundStyle(Color.btText)
                .lineLimit(3)
                .lineSpacing(2)

            Text("▲ \(post.score) · \(post.replies) replies")
                .font(BTFont.monoBold(size: 9))
                .foregroundStyle(Color.btText3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, BTSpacing.sm)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        BoroughCard(borough: "Manhattan", posts: [
            BoroughMini(text: "the woman walking 9 dogs on Ave A is maintaining the EV", score: 631, replies: 52),
        ])
        .padding()
    }
}
