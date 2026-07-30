import SwiftUI

struct DailyPromptCard: View {
    let prompt: DailyPrompt
    /// Real response count. Nil = not loaded yet — show the CTA without a number
    /// rather than invent one (no fake activity counts).
    var answerCount: Int?
    var onTap: (() -> Void)?

    @State private var showPromptFeed = false

    var body: some View {
        Button {
            if let onTap {
                onTap()
            } else {
                showPromptFeed = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                // Head: label + live countdown
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.btLime)
                            .frame(width: 5, height: 5)
                            .shadow(color: Color.btLime.opacity(0.7), radius: 4)
                        Text("THIS WEEK'S PROMPT · NYC WIDE")
                            .font(BTFont.monoBold(size: 9.5))
                            .tracking(1.5)
                            .foregroundStyle(Color.btLime)
                    }
                    Spacer()
                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        Text(prompt.timeRemaining)
                            .font(BTFont.mono(size: 11))
                            .tracking(0.5)
                            .foregroundStyle(Color.btText3)
                    }
                }

                // Question + compact stats on one line — slimmer so real posts
                // lead the feed instead of sitting below a tall prompt card.
                Text(prompt.question)
                    .font(BTFont.display(size: 14))
                    .foregroundStyle(Color.btText)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)

                // Only show a count once we have a real one (>0); otherwise just
                // the CTA — never a fabricated number.
                Group {
                    if let answerCount, answerCount > 0 {
                        Text(answerCount.formatted())
                            .font(BTFont.monoBold(size: 10.5))
                            .foregroundColor(.btLime)
                        + Text(" answers · tap to join →")
                            .font(BTFont.body(size: 10.5))
                            .foregroundColor(.btText2)
                    } else {
                        Text("tap to join →")
                            .font(BTFont.body(size: 10.5))
                            .foregroundColor(.btText2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.btLime.opacity(0.06))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.btLime.opacity(0.18)).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPromptFeed) {
            DailyPromptFeedView(prompt: prompt)
        }
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        DailyPromptCard(
            prompt: DailyPrompt(
                id: UUID(),
                question: "What's the craziest thing you've ever seen in NYC?",
                activeFrom: Date(),
                activeUntil: Date().addingTimeInterval(3600 * 22)
            ),
            answerCount: 1842
        )
    }
}
