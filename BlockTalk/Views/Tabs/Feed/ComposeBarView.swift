import SwiftUI

struct ComposeBarView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BTSpacing.md) {
                Text("what's on your block?")
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText3)

                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.btLime)
            }
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.md)
            .background(Color.btSurface)
            .cornerRadius(BTRadius.full)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.full)
                    .stroke(Color.btLine, lineWidth: 1)
            )
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.bottom, BTSpacing.sm)
        .background(
            LinearGradient(
                colors: [Color.btBg.opacity(0), Color.btBg],
                startPoint: .top,
                endPoint: .center
            )
        )
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack {
            Spacer()
            ComposeBarView { }
        }
    }
}
