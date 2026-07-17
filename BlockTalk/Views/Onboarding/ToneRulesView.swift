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
                            .frame(width: geo.size.width, height: 3)
                    }
                }
                .frame(height: 3)

                Text("03 / 03")
                    .font(BTFont.mono(size: 10))
                    .foregroundStyle(Color.btText3)
                    .tracking(1)
                    .fixedSize()
            }

            Spacer()

            // The one rule
            VStack(alignment: .leading, spacing: 0) {
                Text("ONE RULE")
                    .font(BTFont.mono(size: 12))
                    .foregroundStyle(Color.btPink)
                    .tracking(3)
                    .padding(.bottom, BTSpacing.lg)

                Text("Anonymity isn't a hall pass.")
                    .font(BTFont.display(size: 32))
                    .foregroundStyle(Color.btText)
                    .tracking(-0.8)
                    .lineSpacing(6)
                    .padding(.bottom, BTSpacing.lg)

                Text("Hate speech, racism, and identifying individuals will get you banned.")
                    .font(BTFont.body(size: 16))
                    .foregroundStyle(Color.btText2)
                    .lineSpacing(8)

                Text("Everything else is fair game.")
                    .font(BTFont.bodyBold(size: 16))
                    .foregroundStyle(Color.btText)
                    .lineSpacing(8)
                    .padding(.top, BTSpacing.sm)
            }

            Spacer()

            // CTA — the tap is the acknowledgment record
            Button {
                // Bundled-mock: ensure a user exists when entering via onboarding
                if appState.currentUser == nil { appState.currentUser = .sample }
                appState.selectedTab = 0   // land on the Feed, not wherever we came from
                appState.advanceTo(.app)
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
