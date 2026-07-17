import SwiftUI

struct PinDropOverlay: View {
    var body: some View {
        // The ring is the layout CENTER so it can be pinned exactly to the
        // range-checked coordinate; the stem + shadow hang below it.
        ZStack {
            // Stem + ground shadow, below the ring
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.btLime)
                    .frame(width: 2, height: 24)
                Ellipse()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 12, height: 4)
            }
            .offset(y: 36)

            // Reticle ring — the aim point
            Circle()
                .stroke(Color.btLime, lineWidth: 2.5)
                .frame(width: 44, height: 44)
                .shadow(color: Color.btLime.opacity(0.3), radius: 8, y: 0)
            Circle()
                .fill(Color.btLime)
                .frame(width: 8, height: 8)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        PinDropOverlay()
    }
}
