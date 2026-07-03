import SwiftUI

struct ToneRulesView: View {
    @Environment(AppState.self) private var appState

    private let samplePosts: [(username: String, number: String, text: String, time: String)] = [
        ("BlockTalker", "#0042", "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter.", "2m ago"),
        ("BlockTalker", "#1138", "does anyone else's radiator sound like a full drum kit at 3am or is that just my building", "14m ago"),
        ("BlockTalker", "#0887", "shoutout to whoever put a tiny sweater on the fire hydrant on rivington. art.", "1h ago"),
        ("BlockTalker", "#0219", "that new coffee spot on ave B is mid. I said what I said.", "3h ago"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xxl) {
                // Step indicator
                Text("STEP 03 / 03")
                    .font(BTFont.mono(size: 12))
                    .foregroundStyle(Color.btText3)
                    .padding(.top, BTSpacing.xxxl)

                // Heading
                Text("this is what\nBlockTalk sounds like")
                    .font(BTFont.display(size: 28))
                    .foregroundStyle(Color.btText)
                    .lineSpacing(4)

                // Example PostCards in preview mode
                VStack(spacing: BTSpacing.md) {
                    ForEach(Array(samplePosts.enumerated()), id: \.offset) { _, post in
                        samplePostCard(
                            username: post.username,
                            number: post.number,
                            text: post.text,
                            time: post.time
                        )
                    }
                }

                // Rule panel
                rulePanel

                Spacer(minLength: BTSpacing.xxxl)
            }
            .padding(.horizontal, BTSpacing.xxl)
        }
        .background(Color.btBg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            // "I get it" CTA
            Button {
                appState.advanceTo(.app)
            } label: {
                Text("I get it")
                    .font(BTFont.bodySemibold(size: 16))
                    .foregroundStyle(Color.btBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.lg)
                    .background(Color.btLime)
                    .cornerRadius(BTRadius.md)
            }
            .padding(.horizontal, BTSpacing.xxl)
            .padding(.bottom, BTSpacing.lg)
            .background(Color.btBg)
        }
    }

    // MARK: - Sample Post Card (Preview Mode)

    private func samplePostCard(username: String, number: String, text: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack(spacing: BTSpacing.sm) {
                Text(username)
                    .font(BTFont.bodySemibold(size: 13))
                    .foregroundStyle(Color.btText)
                Text(number)
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
                Spacer()
                Text(time)
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            }
            Text(text)
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText)
                .lineSpacing(4)
        }
        .padding(BTSpacing.lg)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(Color.btLine, lineWidth: 1)
        )
    }

    // MARK: - Rule Panel

    private var rulePanel: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("Anonymity isn't a hall pass.")
                .font(BTFont.bodySemibold(size: 17))
                .foregroundStyle(Color.btPink)

            Text("BlockTalk is for real neighborhood talk — observations, opinions, humor, hot takes. Not hate. Not harassment. Not doxxing.\n\nPosts that identify specific people, contain slurs, or threaten violence will be removed. Repeat offenders get permanently blocked.\n\nKeep it real. Keep it anonymous. Keep it about the block.")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText2)
                .lineSpacing(5)
        }
        .padding(BTSpacing.xl)
        .background(Color.btPink.opacity(0.08))
        .cornerRadius(BTRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.lg)
                .stroke(Color.btPink.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ToneRulesView()
        .environment(AppState())
}
