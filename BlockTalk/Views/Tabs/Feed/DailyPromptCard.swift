import SwiftUI

struct DailyPromptCard: View {
    let prompt: DailyPrompt
    var answerCount: Int = 0
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
            VStack(alignment: .leading, spacing: BTSpacing.md) {
                // Top row: DAILY PROMPT + LIVE pill + countdown
                HStack(spacing: BTSpacing.sm) {
                    Text("DAILY PROMPT")
                        .font(BTFont.mono(size: 10))
                        .foregroundStyle(Color.btBg)

                    livePill

                    Spacer()

                    // Live countdown — re-renders every 30s from activeUntil
                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        Text(prompt.timeRemaining)
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(Color.btBg.opacity(0.7))
                    }
                }

                // Question
                Text(prompt.question)
                    .font(BTFont.bodySemibold(size: 16))
                    .foregroundStyle(Color.btBg)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)

                // Bottom row
                HStack {
                    if answerCount > 0 {
                        Text("\(answerCount) answers")
                            .font(BTFont.body(size: 12))
                            .foregroundStyle(Color.btBg.opacity(0.7))
                    }

                    Spacer()

                    HStack(spacing: BTSpacing.xs) {
                        Text("Answer")
                            .font(BTFont.bodySemibold(size: 13))
                            .foregroundStyle(Color.btBg)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.btBg)
                    }
                }
            }
            .padding(BTSpacing.lg)
            .background(Color.btLime)
            .cornerRadius(BTRadius.lg)
        }
        .sheet(isPresented: $showPromptFeed) {
            DailyPromptFeedView(prompt: prompt)
        }
    }

    private var livePill: some View {
        HStack(spacing: BTSpacing.xs) {
            Circle()
                .fill(Color.btPink)
                .frame(width: 6, height: 6)
            Text("LIVE")
                .font(BTFont.monoBold(size: 9))
                .foregroundStyle(Color.btBg)
        }
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, BTSpacing.xs)
        .background(Color.btBg.opacity(0.15))
        .cornerRadius(BTRadius.full)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        DailyPromptCard(
            prompt: DailyPrompt(
                id: UUID(),
                question: "What's the most underrated spot in your neighborhood?",
                activeFrom: Date(),
                activeUntil: Date().addingTimeInterval(3600 * 8)
            ),
            answerCount: 47
        )
        .padding()
    }
}
