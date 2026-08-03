import SwiftUI

// Vote logic identical on every vote surface (§8): score hidden until you vote;
// after the first tap on either arrow BOTH counts appear and stay visible even
// if you un-vote; counts are independent, never netted. Down-count derivation:
// max(0, round(score × 0.06)). Users can vote on their own posts.
struct VotePills: View {
    var score: Int
    var upvoteCount: Int
    var downvoteCount: Int
    var onUpvote: () -> Void
    var onDownvote: () -> Void
    /// Tapping your active arrow again clears the vote — delete the row.
    var onClear: () -> Void = {}

    @State private var vote: Int = 0        // -1, 0, 1
    @State private var hasEverVoted = false

    private var upCount: Int { upvoteCount + (vote == 1 ? 1 : 0) }
    private var downCount: Int { downvoteCount + (vote == -1 ? 1 : 0) }

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            pill(glyph: "▲", color: .btLime, active: vote == 1,
                 count: hasEverVoted ? upCount : nil, action: tapUp)
            pill(glyph: "▽", color: .btPink, active: vote == -1,
                 count: hasEverVoted ? downCount : nil, action: tapDown)
        }
        .animation(.easeOut(duration: 0.16), value: hasEverVoted)
        .animation(.easeOut(duration: 0.16), value: vote)
    }

    private func tapUp() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if vote == 1 { vote = 0; onClear() } else { vote = 1; onUpvote() }
        hasEverVoted = true
    }

    private func tapDown() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if vote == -1 { vote = 0; onClear() } else { vote = -1; onDownvote() }
        hasEverVoted = true
    }

    private func pill(glyph: String, color: Color, active: Bool, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(glyph)
                    .font(BTFont.bodyBold(size: 11))
                    .foregroundStyle(color)
                if let count {
                    Text("\(count)")
                        .font(BTFont.monoBold(size: 11))
                        .foregroundStyle(color)
                        .contentTransition(.numericText())
                }
            }
            .frame(height: 30)
            .padding(.horizontal, 11)
            .background(active ? color.opacity(0.10) : Color.btSurface)
            .overlay(Capsule().stroke(active ? color.opacity(0.45) : Color.btLine, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.xl) {
            VotePills(score: 42, upvoteCount: 45, downvoteCount: 3, onUpvote: {}, onDownvote: {})
            VotePills(score: 0, upvoteCount: 0, downvoteCount: 0, onUpvote: {}, onDownvote: {})
        }
    }
}
