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
