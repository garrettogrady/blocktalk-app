import SwiftUI

struct Tombstone: View {
    enum Variant {
        case reporter
        case underReview
        case removed
    }

    let variant: Variant
    var onShowAnyway: (() -> Void)?
    var onAppeal: (() -> Void)?

    @State private var isRevealed = false

    var body: some View {
        switch variant {
        case .reporter:
            reporterView
        case .underReview:
            underReviewView
        case .removed:
            removedView
        }
    }

    // MARK: - Reporter Variant

    private var reporterView: some View {
        VStack(spacing: BTSpacing.md) {
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.btText3)

                Text("You reported this post. It's hidden for you.")
                    .font(BTFont.body(size: 13))
                    .foregroundStyle(Color.btText3)

                Spacer()
            }

            if !isRevealed {
                Button {
                    withAnimation { isRevealed = true }
                    onShowAnyway?()
                } label: {
                    Text("Show anyway")
                        .font(BTFont.bodySemibold(size: 13))
                        .foregroundStyle(Color.btText2)
                        .padding(.horizontal, BTSpacing.md)
                        .padding(.vertical, BTSpacing.sm)
                        .background(Color.btSurface)
                        .cornerRadius(BTRadius.full)
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.full)
                                .stroke(Color.btLine, lineWidth: 1)
                        )
                }
            }
        }
        .padding(BTSpacing.lg)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.md)
    }

    // MARK: - Under Review Variant

    private var underReviewView: some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 16))
                .foregroundStyle(Color.btWarn)

            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text("Under review")
                    .font(BTFont.bodySemibold(size: 14))
                    .foregroundStyle(Color.btWarn)

                Text("This post is being reviewed by moderators and is temporarily hidden.")
                    .font(BTFont.body(size: 13))
                    .foregroundStyle(Color.btText2)
            }

            Spacer()
        }
        .padding(BTSpacing.lg)
        .background(Color.btWarn.opacity(0.08))
        .cornerRadius(BTRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(Color.btWarn.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Removed Variant

    private var removedView: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: "xmark.shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.btPink)

                Text("Post removed")
                    .font(BTFont.bodySemibold(size: 14))
                    .foregroundStyle(Color.btPink)

                Spacer()
            }

            Text("This post was removed for violating community guidelines.")
                .font(BTFont.body(size: 13))
                .foregroundStyle(Color.btText2)

            if let onAppeal {
                Button {
                    onAppeal()
                } label: {
                    Text("Appeal this decision")
                        .font(BTFont.bodySemibold(size: 13))
                        .foregroundStyle(Color.btPink)
                        .padding(.horizontal, BTSpacing.md)
                        .padding(.vertical, BTSpacing.sm)
                        .background(Color.btPink.opacity(0.12))
                        .cornerRadius(BTRadius.full)
                }
            }
        }
        .padding(BTSpacing.lg)
        .background(Color.btPink.opacity(0.06))
        .cornerRadius(BTRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(Color.btPink.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.lg) {
            Tombstone(variant: .reporter)
            Tombstone(variant: .underReview)
            Tombstone(variant: .removed, onAppeal: {})
        }
        .padding()
    }
}
