import SwiftUI

struct IdentityStrip: View {
    let user: BlockTalkUser
    var postCount: Int = 0
    var replyCount: Int = 0
    var totalScore: Int = 0

    var body: some View {
        VStack(spacing: BTSpacing.lg) {
            // Avatar + identity info
            HStack(spacing: BTSpacing.lg) {
                // Lime circle avatar with initial
                ZStack {
                    Circle()
                        .fill(Color.btLime)
                        .frame(width: 56, height: 56)

                    Text(String(user.username.prefix(1)).uppercased())
                        .font(BTFont.display(size: 24))
                        .foregroundStyle(Color.btBg)
                }

                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    // User number in mono
                    Text("#\(String(format: "%04d", user.userNumber))")
                        .font(BTFont.mono(size: 13))
                        .foregroundStyle(Color.btText3)

                    // @username
                    Text("@\(user.username)")
                        .font(BTFont.bodySemibold(size: 18))
                        .foregroundStyle(Color.btText)

                    // Home badge
                    if user.homeNeighborhoodId != nil {
                        HomeBadge(shortCode: "HOME")
                    }
                }

                Spacer()
            }

            // Stats line
            HStack(spacing: BTSpacing.xs) {
                Text("\(postCount) posts")
                    .font(BTFont.body(size: 13))
                    .foregroundStyle(Color.btText2)

                Text("·")
                    .foregroundStyle(Color.btText3)

                Text("\(replyCount) replies")
                    .font(BTFont.body(size: 13))
                    .foregroundStyle(Color.btText2)

                Text("·")
                    .foregroundStyle(Color.btText3)

                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .semibold))
                    Text("\(totalScore)")
                        .font(BTFont.body(size: 13))
                }
                .foregroundStyle(Color.btText2)

                Spacer()
            }
        }
        .padding(BTSpacing.lg)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.lg)
                .stroke(Color.btLine, lineWidth: 1)
        )
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
