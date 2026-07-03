import SwiftUI

struct OfflineBanner: View {
    var pendingPostCount: Int = 0

    var body: some View {
        HStack(spacing: BTSpacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12))
                .foregroundStyle(Color.btText3)

            if pendingPostCount > 0 {
                Text("offline · \(pendingPostCount) post\(pendingPostCount == 1 ? "" : "s") will send when you're back")
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            } else {
                Text("offline · your posts will send when you're back online")
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            }

            Spacer()
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.btSurface2)
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack {
            OfflineBanner()
            OfflineBanner(pendingPostCount: 3)
        }
    }
}
