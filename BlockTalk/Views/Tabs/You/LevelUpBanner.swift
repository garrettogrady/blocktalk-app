import SwiftUI

/// One-time banner above the identity card on the next You-tab visit after a
/// level-up. Dismissible; no full-screen takeover, no confetti.
struct LevelUpBanner: View {
    let level: AuthorityLevel
    var onDismiss: () -> Void

    private var tier: AuthorityTier { level.tier }

    var body: some View {
        HStack(alignment: .center, spacing: BTSpacing.md) {
            RoundedRectangle(cornerRadius: BTRadius.md)
                .fill(tier.color)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(level.roman)
                        .font(BTFont.monoBold(size: 12))
                        .foregroundStyle(Color.btOnAccent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(level.name)
                    .font(BTFont.display(size: 15))
                    .tracking(-0.15)
                    .foregroundStyle(tier.color)
                Text("You leveled up. Your badge changed on every post you've written.")
                    .font(BTFont.body(size: 11.5))
                    .foregroundStyle(Color.btText2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.btText3)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(14)
        .background(
            LinearGradient(colors: [tier.color.opacity(0.20), tier.color.opacity(0.05)],
                           startPoint: .leading, endPoint: .trailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(tier.color.opacity(0.42), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }
}

/// Remembers the last level the user has been shown, per user, so the banner
/// appears once per level and never again after dismissal.
enum LevelUpTracker {
    private static func key(_ userId: UUID) -> String { "authority.lastSeenLevel.\(userId.uuidString)" }

    /// The level to celebrate, or nil. A missing record (first launch after this
    /// shipped, or a fresh install) is written silently and shows nothing.
    static func pendingLevel(userId: UUID, aura: Int) -> AuthorityLevel? {
        let current = Authority.level(for: aura)
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: key(userId)) != nil else {
            defaults.set(current.index, forKey: key(userId))
            return nil
        }
        return current.index > defaults.integer(forKey: key(userId)) ? current : nil
    }

    static func markSeen(userId: UUID, aura: Int) {
        UserDefaults.standard.set(Authority.level(for: aura).index, forKey: key(userId))
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.md) {
            LevelUpBanner(level: AuthorityLevel(index: 12)) {}
            LevelUpBanner(level: AuthorityLevel(index: 4)) {}
            LevelUpBanner(level: AuthorityLevel(index: 2)) {}
        }
        .padding()
    }
}
