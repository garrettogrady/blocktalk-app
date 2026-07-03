import SwiftUI

struct VotePills: View {
    var score: Int
    var onUpvote: () -> Void
    var onDownvote: () -> Void

    @State private var userVote: Int = 0 // -1, 0, 1
    @State private var hasVoted = false

    private var displayUp: Int {
        max(0, score + (userVote == 1 ? 1 : 0))
    }

    private var displayDown: Int {
        max(0, abs(min(0, score)) + (userVote == -1 ? 1 : 0))
    }

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            // Upvote button
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                if userVote == 1 {
                    userVote = 0
                } else {
                    userVote = 1
                    onUpvote()
                }
                hasVoted = true
            } label: {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 14))
                    if hasVoted {
                        Text("\(displayUp)")
                            .font(BTFont.mono(size: 12))
                    }
                }
                .foregroundStyle(userVote == 1 ? Color.btLime : Color.btText3)
                .padding(.horizontal, BTSpacing.sm)
                .padding(.vertical, BTSpacing.xs)
                .background(
                    userVote == 1
                        ? Color.btLime.opacity(0.12) : Color.btSurface2
                )
                .cornerRadius(BTRadius.full)
            }

            // Downvote button (visible after first vote)
            if hasVoted || userVote != 0 {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()

                    if userVote == -1 {
                        userVote = 0
                    } else {
                        userVote = -1
                        onDownvote()
                    }
                } label: {
                    HStack(spacing: BTSpacing.xs) {
                        Image(systemName: userVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .font(.system(size: 14))
                        Text("\(displayDown)")
                            .font(BTFont.mono(size: 12))
                    }
                    .foregroundStyle(userVote == -1 ? Color.btPink : Color.btText3)
                    .padding(.horizontal, BTSpacing.sm)
                    .padding(.vertical, BTSpacing.xs)
                    .background(
                        userVote == -1
                            ? Color.btPink.opacity(0.12) : Color.btSurface2
                    )
                    .cornerRadius(BTRadius.full)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.xl) {
            VotePills(score: 42, onUpvote: {}, onDownvote: {})
            VotePills(score: 0, onUpvote: {}, onDownvote: {})
        }
    }
}
