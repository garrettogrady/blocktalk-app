import SwiftUI

struct PinBadge: View {
    let cornerName: String

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            Image(systemName: "mappin")
                .font(.system(size: 9))
            Text(cornerName)
                .font(BTFont.mono(size: 9))
        }
        .foregroundStyle(Color.btLime)
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, 2)
        .background(Color.btLime.opacity(0.12))
        .cornerRadius(BTRadius.full)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.md) {
            PinBadge(cornerName: "7th & Ave A")
            PinBadge(cornerName: "Broadway & Houston")
        }
    }
}
