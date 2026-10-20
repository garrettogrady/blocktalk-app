import SwiftUI

struct AuthorityBadge: View {
    let level: AuthorityLevel

    var body: some View {
        Text(level.name.uppercased())
            .font(BTFont.monoBold(size: 9))
            .tracking(0.63)                 // 0.07em at 9pt
            .lineLimit(1)
            .fixedSize()                    // never wraps, never truncates
            .foregroundStyle(level.tier.color)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, 2)
            .background(level.tier.color.opacity(level.tier.badgeFillOpacity))
            .overlay(Capsule().strokeBorder(level.tier.color.opacity(level.tier.badgeStrokeOpacity), lineWidth: 1))
            .clipShape(Capsule())
    }
}

/// Permanent chip for the first 50 accounts to post from a neighborhood (Day
/// One). Same capsule and type as AuthorityBadge so it reads as native; gold
/// is used for nothing else in the app, so it reads as rare. Text only: no
/// glyph survives 9pt legibly. Pass `shortCode` only when the slot's
/// neighborhood differs from the author's current home, so the chip never
/// claims a neighborhood the home badge contradicts.
struct DayOneBadge: View {
    var shortCode: String? = nil

    var body: some View {
        Text(shortCode.map { "DAY ONE · \($0.uppercased())" } ?? "DAY ONE")
            .font(BTFont.monoBold(size: 9))
            .tracking(0.63)
        .lineLimit(1)
        .fixedSize()
        .foregroundStyle(Color.btGold)
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, 2)
        .background(Color.btGold.opacity(0.12))
        .overlay(Capsule().strokeBorder(Color.btGold.opacity(0.42), lineWidth: 1))
        .clipShape(Capsule())
    }
}

#Preview("Day One") {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                DayOneBadge()
                AuthorityBadge(level: AuthorityLevel(index: 5))
                HomeBadge(shortCode: "LES")
            }
            HStack(spacing: 6) {
                DayOneBadge(shortCode: "FIDI")
                AuthorityBadge(level: AuthorityLevel(index: 2))
                HomeBadge(shortCode: "LES")
            }
        }
    }
}
