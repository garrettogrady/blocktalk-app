import SwiftUI

/// The drop reticle. Laid out bottom-up so the foot of the stem (the ground
/// shadow) is the view's bottom edge. MapView positions it so that foot sits
/// exactly on the reticle point; the ring floats above it. Users read the point
/// where the pin meets the ground as "the spot", so that is what has to sit on
/// their location, not the ring.
struct PinDropOverlay: View {
    /// Ring (44) + stem (22). MapView uses this to place the foot on a point.
    static let height: CGFloat = 66

    var body: some View {
        VStack(spacing: 0) {
            // Reticle ring with the center dot
            ZStack {
                Circle()
                    .stroke(Color.btLime, lineWidth: 2.5)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.btLime.opacity(0.3), radius: 8, y: 0)
                Circle()
                    .fill(Color.btLime)
                    .frame(width: 8, height: 8)
            }
            // Stem down to the ground
            Rectangle()
                .fill(Color.btLime)
                .frame(width: 2, height: 22)
        }
        // Ground shadow straddles the bottom edge so the stem visibly touches
        // the map at the anchor point.
        .overlay(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 14, height: 5)
                .offset(y: 2)
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
