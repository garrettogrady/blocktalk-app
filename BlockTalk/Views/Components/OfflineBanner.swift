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

/// A post that aged out of the pending queue before it could send.
struct DiscardedPostRow: View {
    let post: Post
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack(spacing: 7) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.btText3)
                Text("HELD TOO LONG · COULDN'T SEND")
                    .font(BTFont.monoBold(size: 9.5))
                    .tracking(1.4)
                    .foregroundStyle(Color.btText3)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.btText3)
                }
                .buttonStyle(.plain)
            }

            Text("\"\(post.text)\"")
                .font(BTFont.body(size: 13))
                .italic()
                .foregroundStyle(Color.btText2)
                .textSelection(.enabled)

            Button {
                ShareHelper.shareText(post.text)
            } label: {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "doc.on.doc").font(.system(size: 11))
                    Text("Tap to copy text").font(BTFont.bodySemibold(size: 12))
                }
                .foregroundStyle(Color.btText2)
                .padding(.horizontal, BTSpacing.md)
                .padding(.vertical, BTSpacing.sm)
                .background(Color.btSurface2)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(BTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }
}

/// Shared "couldn't load" state with a retry, so a failed fetch reads as an
/// error instead of a false "nothing here."
struct LoadErrorView: View {
    var message: String = "Couldn't load. Check your connection and try again."
    let retry: () -> Void

    var body: some View {
        VStack(spacing: BTSpacing.md) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 30))
                .foregroundStyle(Color.btText3)
            Text("Something went wrong")
                .font(BTFont.bodySemibold(size: 15))
                .foregroundStyle(Color.btText)
            Text(message)
                .font(BTFont.body(size: 13))
                .foregroundStyle(Color.btText3)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text("Try again")
                    .font(BTFont.bodySemibold(size: 14))
                    .foregroundStyle(Color.btOnAccent)
                    .padding(.horizontal, BTSpacing.xl)
                    .padding(.vertical, BTSpacing.sm)
                    .background(Color.btLime)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, BTSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BTSpacing.xxxl)
        .padding(.horizontal, BTSpacing.xl)
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
