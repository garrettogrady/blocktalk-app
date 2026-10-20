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

// MARK: - Day One

/// You-tab tile for a Day One member: their neighborhood and slot number, tap
/// for the explainer.
struct DayOneTile: View {
    let slot: DayOneSlot
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BTSpacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Day One")
                        .font(BTFont.display(size: 18))
                        .tracking(-0.2)
                        .foregroundStyle(Color.btGold)
                    Text((slot.neighborhoodName ?? slot.shortCode ?? "YOUR NEIGHBORHOOD").uppercased() + " · PERMANENT")
                        .font(BTFont.mono(size: 10))
                        .tracking(0.3)
                        .foregroundStyle(Color.btText3)
                        .lineLimit(1)
                }
                Spacer(minLength: BTSpacing.sm)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(slot.rank)")
                        .font(BTFont.display(size: 26))
                        .foregroundStyle(Color.btGold)
                    Text("OF \(DayOneSlot.capacity)")
                        .font(BTFont.mono(size: 9))
                        .tracking(0.8)
                        .foregroundStyle(Color.btText3)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.btText3)
            }
            .padding(BTSpacing.lg)
            .background(Color.btSurface)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .strokeBorder(Color.btGoldDim, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        }
        .buttonStyle(.plain)
    }
}

/// What the badge is, in a few lines. The only place in the app that
/// explains it; the chip itself never needs to.
struct DayOneSheet: View {
    let slot: DayOneSlot
    @Environment(\.dismiss) private var dismiss

    private var hood: String { slot.neighborhoodName ?? slot.shortCode ?? "your neighborhood" }

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.lg) {
            HStack {
                DayOneBadge()
                Spacer()
                Button("Done") { dismiss() }
                    .font(BTFont.bodySemibold(size: 15))
                    .foregroundStyle(Color.btLime)
            }
            Text("You were here on day one.")
                .font(BTFont.display(size: 28))
                .tracking(-0.4)
                .foregroundStyle(Color.btText)
            Text("You're number \(slot.rank) of the first \(DayOneSlot.capacity) people from \(hood) to post on BlockTalk. The badge is permanent, it shows on every post and reply you make, and nobody can earn it once the fiftieth slot is taken.")
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText2)
            VStack(alignment: .leading, spacing: BTSpacing.sm) {
                row("It stays with \(hood) even if you move, and it never changes with your level.")
                row("It gives no extra aura, votes, or reach. Everyone earns authority the same way.")
                row("You'll be first to try new neighborhoods before they open.")
            }
            Spacer()
        }
        .padding(BTSpacing.lg)
        .padding(.top, BTSpacing.sm)
        .background(Color.btBg.ignoresSafeArea())
    }

    private func row(_ text: String) -> some View {
        HStack(alignment: .top, spacing: BTSpacing.sm) {
            Circle()
                .fill(Color.btGold)
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(text)
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText2)
        }
    }
}

#Preview("Day One tile") {
    let slot = DayOneSlot(neighborhoodId: UUID(), rank: 12, userId: UUID(),
                          shortCode: "LES", neighborhoodName: "Lower East Side")
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.lg) {
            DayOneTile(slot: slot) {}
            DayOneSheet(slot: slot)
        }
        .padding()
    }
}
