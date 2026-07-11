import SwiftUI

// Vote logic identical on every vote surface (§8): score hidden until you vote;
// after the first tap on either arrow BOTH counts appear and stay visible even
// if you un-vote; counts are independent, never netted. Down-count derivation:
// max(0, round(score × 0.06)). Users can vote on their own posts.
struct VotePills: View {
    var score: Int
    var onUpvote: () -> Void
    var onDownvote: () -> Void

    @State private var vote: Int = 0        // -1, 0, 1
    @State private var hasEverVoted = false

    private var upBase: Int { max(0, score) }
    private var downBase: Int { max(0, Int((Double(score) * 0.06).rounded())) }
    private var upCount: Int { upBase + (vote == 1 ? 1 : 0) }
    private var downCount: Int { downBase + (vote == -1 ? 1 : 0) }

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            pill(glyph: "▲", color: .btLime, active: vote == 1,
                 count: upCount, showCount: hasEverVoted, action: tapUp)
            pill(glyph: "▽", color: .btPink, active: vote == -1,
                 count: downCount, showCount: hasEverVoted, action: tapDown)
        }
    }

    private func tapUp() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if vote == 1 { vote = 0 } else { vote = 1; onUpvote() }
        hasEverVoted = true
    }

    private func tapDown() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if vote == -1 { vote = 0 } else { vote = -1; onDownvote() }
        hasEverVoted = true
    }

    private func pill(glyph: String, color: Color, active: Bool, count: Int, showCount: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(glyph)
                    .font(BTFont.bodyBold(size: 11))
                    .foregroundStyle(color)
                // Count space is always reserved so the pills never resize /
                // shove each other when the score reveals on first vote.
                Text("\(count)")
                    .font(BTFont.monoBold(size: 11))
                    .foregroundStyle(color)
                    .opacity(showCount ? 1 : 0)
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
            VotePills(score: 42, onUpvote: {}, onDownvote: {})
            VotePills(score: 0, onUpvote: {}, onDownvote: {})
        }
    }
}
