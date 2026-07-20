import SwiftUI

// Single-rule onboarding screen (step 03 / 03). The example-post cards were
// removed 2026-06-27 — the feed teaches the voice. Nothing to scroll: the one
// conduct rule fills the screen, and the tap is the acknowledgment record.
struct ToneRulesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step 03 / 03 — matches the Profile step bar (bar left, counter right)
            HStack(spacing: BTSpacing.sm) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.btSurface2)
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.btLime)
                            .frame(width: geo.size.width * 0.5, height: 3)
                    }
                }
                .frame(height: 3)

                Text("01 / 02")
                    .font(BTFont.mono(size: 10))
                    .foregroundStyle(Color.btText3)
                    .tracking(1)
                    .fixedSize()
            }

            Spacer(minLength: BTSpacing.xl)

            // The one rule — big enough that skimming still lands it
            VStack(alignment: .leading, spacing: 0) {
                Text("ONE RULE")
                    .font(BTFont.monoBold(size: 13))
                    .foregroundStyle(Color.btPink)
                    .tracking(3)
                    .padding(.bottom, BTSpacing.lg)

                Text("Anonymity isn't a hall pass.")
                    .font(BTFont.display(size: 44))
                    .foregroundStyle(Color.btText)
                    .tracking(-1)
                    .lineSpacing(4)
                    .padding(.bottom, BTSpacing.xl)

                Text("Hate speech, racism, and identifying individuals will get you banned.")
                    .font(BTFont.body(size: 20))
                    .foregroundStyle(Color.btText2)
                    .lineSpacing(8)

                Text("Everything else is fair game.")
                    .font(BTFont.bodyBold(size: 20))
                    .foregroundStyle(Color.btText)
                    .lineSpacing(8)
                    .padding(.top, BTSpacing.md)
            }

            Spacer(minLength: BTSpacing.xl)

            // CTA — the tap is the acknowledgment record; then set up your profile
            Button {
                appState.advanceTo(.profile)
            } label: {
                Text("I get it")
                    .font(BTFont.bodyBold(size: 14))
                    .foregroundStyle(Color.btOnAccent)
                    .tracking(0.4)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.btLime)
                    .cornerRadius(BTRadius.lg)
            }
        }
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.top, BTSpacing.sm)
        .padding(.bottom, BTSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.btBg.ignoresSafeArea())
    }
}

#Preview {
    ToneRulesView()
        .environment(AppState())
}
