import SwiftUI

struct AuthorityProgressBar: View {
    let progress: Double
    let tier: AuthorityTier

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.btElev)
                Capsule()
                    .fill(LinearGradient(colors: [tier.dimColor, tier.color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityValue("\(Int((progress * 100).rounded(.down))) percent")
    }
}
