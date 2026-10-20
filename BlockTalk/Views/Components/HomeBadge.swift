import SwiftUI

struct HomeBadge: View {
    let shortCode: String

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            Image(systemName: "house.fill")
                .font(.system(size: 9))
            Text(shortCode)
                .font(BTFont.mono(size: 9))
        }
        // Never wraps: when the meta row is tight the username truncates instead.
        .lineLimit(1)
        .fixedSize()
        .foregroundStyle(Color.btHouse)
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, 2)
        .background(Color.btHouse.opacity(0.12))
        .cornerRadius(BTRadius.full)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.md) {
            HomeBadge(shortCode: "LES")
            HomeBadge(shortCode: "WILLYB")
            HomeBadge(shortCode: "UES")
        }
    }
}
