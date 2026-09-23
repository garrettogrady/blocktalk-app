import SwiftUI

// Single-rule onboarding screen (step 03 / 03). The example-post cards were
// removed 2026-06-27 — the feed teaches the voice. Nothing to scroll: the one
// conduct rule fills the screen, and the tap is the acknowledgment record.
struct ToneRulesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step 01 / 03 — rule, then neighborhood, then username
            HStack(spacing: BTSpacing.sm) {
                Button { appState.advanceTo(.how) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.btText2)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.btSurface2)
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.btLime)
                            .frame(width: geo.size.width / 3, height: 3)
                    }
                }
                .frame(height: 3)

                Text("01 / 03")
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

// MARK: - How it works (the one crisp beat)

/// A single explainer shown once, right after sign-in, so the thing that makes
/// blocktalk different — presence-locked posting — is framed as the magic
/// before it's ever hit as a restriction.
struct HowItWorksView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HOW IT WORKS")
                .font(BTFont.monoBold(size: 13))
                .foregroundStyle(Color.btLime)
                .tracking(3)
                .padding(.bottom, BTSpacing.lg)

            Text("Talk about where you actually are.")
                .font(BTFont.display(size: 34))
                .foregroundStyle(Color.btText)
                .tracking(-0.8)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // The three beats sit centered in the space between headline and button
            // rather than stacking under the headline and leaving the bottom empty.
            Spacer(minLength: BTSpacing.xl)

            VStack(alignment: .leading, spacing: BTSpacing.sm) {
                row("mappin",
                    "Post where you are.",
                    "You can only post in the neighborhood you're physically located in. Real presence, authentic commentary.")

                row("text.bubble",
                    "Read and reply anywhere.",
                    "Browse any neighborhood in the city. Reading, voting and replying work from anywhere. Only posting needs you there.")

                row("map",
                    "Drop it on the map.",
                    "Tag the exact corner or business where something happened. Your comment lives on the spot.")
            }

            Spacer(minLength: BTSpacing.xl)

            Button {
                appState.advanceTo(.tone)
            } label: {
                Text("Got it")
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
        .padding(.top, BTSpacing.xxxl)
        .padding(.bottom, BTSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.btBg.ignoresSafeArea())
    }

    private func row(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .center, spacing: BTSpacing.lg) {
            litKey(symbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BTFont.bodyBold(size: 17))
                    .foregroundStyle(Color.btText)
                Text(body)
                    .font(BTFont.body(size: 14))
                    .foregroundStyle(Color.btText2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, BTSpacing.md)
    }

    /// A backlit key: dark glass face with a hairline top highlight, the glyph
    /// glowing lime through it, and a soft bloom behind the whole thing.
    private func litKey(_ symbol: String) -> some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(LinearGradient(colors: [Color.btElev, Color.btSurface],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 46, height: 46)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.btLine, lineWidth: 1))
            .overlay(
                // One-pixel highlight along the top edge, fading out halfway down.
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
            )
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.btLime)
                    .shadow(color: Color.btLime.opacity(0.55), radius: 5)
            )
            .shadow(color: Color.btLime.opacity(0.22), radius: 12, y: 8)
            // Soft bloom behind the key. A background, not a sibling, so it never
            // affects the key's own size or the row layout.
            .background(
                Circle()
                    .fill(RadialGradient(colors: [Color.btLime.opacity(0.16), .clear],
                                         center: .center, startRadius: 0, endRadius: 38))
                    .frame(width: 76, height: 76)
            )
    }
}

#Preview("How it works") {
    HowItWorksView()
        .environment(AppState())
}
