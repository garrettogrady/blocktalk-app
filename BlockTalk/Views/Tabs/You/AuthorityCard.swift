import SwiftUI

/// You-tab summary card: level name, progress to the next level, levels left.
/// Tapping pushes AuthorityView. Styled to match the Notifications card.
/// Shows no aura figures anywhere (the app publishes the ranking, never the math).
struct AuthorityCard: View {
    let aura: Int
    var onTap: () -> Void

    private var level: AuthorityLevel { Authority.level(for: aura) }
    private var tier: AuthorityTier { level.tier }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BTSpacing.md) {
                HStack(spacing: BTSpacing.sm) {
                    Text("⚡ AUTHORITY")
                        .font(BTFont.monoBold(size: 10))
                        .tracking(1)
                        .foregroundStyle(Color.btText3)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.btText3)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(level.name)
                        .font(BTFont.display(size: 20))
                        .tracking(-0.2)
                        .foregroundStyle(tier.color)
                    Text("LEVEL \(level.index) OF \(Authority.levelCount)")
                        .font(BTFont.mono(size: 10))
                        .tracking(0.3)
                        .foregroundStyle(Color.btText3)
                }

                VStack(alignment: .leading, spacing: 7) {
                    AuthorityProgressBar(progress: Authority.progress(for: aura), tier: tier)
                    HStack(alignment: .firstTextBaseline) {
                        leftCaption
                        Spacer(minLength: BTSpacing.sm)
                        Text(rightCaption)
                            .foregroundStyle(Color.btText3)
                    }
                    .font(BTFont.mono(size: 10))
                    .tracking(0.3)
                    .lineLimit(1)
                }
            }
            .padding(BTSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.btSurface)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(Color.btLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Authority, \(level.name), level \(level.index) of \(Authority.levelCount)")
    }

    private var leftCaption: Text {
        if let next = level.next {
            return Text("\(Authority.percent(for: aura))%").foregroundStyle(Color.btText2)
                + Text(" TO \(next.name.uppercased())").foregroundStyle(Color.btText3)
        }
        return Text("TOP LEVEL").foregroundStyle(Color.btText2)
    }

    private var rightCaption: String {
        let left = Authority.levelsRemaining(for: aura)
        if left == 0 { return "NOTHING ABOVE THIS" }
        return left == 1 ? "1 LEVEL LEFT" : "\(left) LEVELS LEFT"
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.md) {
            AuthorityCard(aura: 12_936) {}
            AuthorityCard(aura: 650) {}
            AuthorityCard(aura: 0) {}
            AuthorityCard(aura: 22_800) {}
        }
        .padding()
    }
}
