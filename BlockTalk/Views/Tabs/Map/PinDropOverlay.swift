import SwiftUI

struct PinDropOverlay: View {
    var body: some View {
        VStack(spacing: 0) {
            // Center reticle: 44px lime ring with center dot
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.btLime, lineWidth: 2.5)
                    .frame(width: 44, height: 44)

                // Center dot
                Circle()
                    .fill(Color.btLime)
                    .frame(width: 8, height: 8)
            }
            .shadow(color: Color.btLime.opacity(0.3), radius: 8, y: 0)

            // Stem
            Rectangle()
                .fill(Color.btLime)
                .frame(width: 2, height: 24)

            // Shadow dot at bottom of stem
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: 12, height: 4)
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
