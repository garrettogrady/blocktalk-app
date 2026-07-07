import SwiftUI

struct IdentityStrip: View {
    let user: BlockTalkUser
    var postCount: Int = 0
    var replyCount: Int = 0
    var totalScore: Int = 0
    var homeShortCode: String = "LES"

    var body: some View {
        HStack(alignment: .top, spacing: BTSpacing.lg) {
            // Lime squircle avatar with initial
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.btLime)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(BTFont.display(size: 26))
                        .foregroundStyle(Color.btOnAccent)
                )

            VStack(alignment: .leading, spacing: 4) {
                // User number is the headline (lime)
                Text("#\(user.userNumber.formatted(.number))")
                    .font(BTFont.monoBold(size: 22))
                    .foregroundStyle(Color.btLime)

                // @username · home badge
                HStack(spacing: BTSpacing.xs) {
                    Text("@\(user.username)")
                        .font(BTFont.bodySemibold(size: 13))
                        .foregroundStyle(Color.btText2)
                    HomeBadge(shortCode: homeShortCode)
                }

                // Stats
                HStack(spacing: 0) {
                    Text("\(postCount)").foregroundStyle(Color.btText)
                    Text(" posts   ·   ").foregroundStyle(Color.btText2)
                    Text("\(replyCount)").foregroundStyle(Color.btText)
                    Text(" replies   ·   ").foregroundStyle(Color.btText2)
                    Text("▲ \(totalScore.formatted())").foregroundStyle(Color.btText)
                }
                .font(BTFont.monoBold(size: 12))
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(BTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        IdentityStrip(
            user: BlockTalkUser(
                id: UUID(),
                username: "nyclocal",
                userNumber: 42,
                homeNeighborhoodId: UUID()
            ),
            postCount: 12,
            replyCount: 34,
            totalScore: 89
        )
        .padding()
    }
}
