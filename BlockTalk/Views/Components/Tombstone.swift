import SwiftUI

struct Tombstone: View {
    enum Variant {
        case reporter
        case underReview
        case removed
    }

    let variant: Variant
    var reasonShort: String?
    var bodyText: String?
    var reportCount: Int = 3
    var appealed: Bool = false
    var onShowAnyway: (() -> Void)?
    var onAppeal: (() -> Void)?

    private var reasonUpper: String { (reasonShort ?? "").uppercased() }

    var body: some View {
        switch variant {
        case .reporter: reporterView
        case .underReview: underReviewView
        case .removed: removedView
        }
    }

    // MARK: - Reporter

    private var reporterView: some View {
        card(border: Color.btLine, fill: Color.btSurface) {
            labelRow(icon: "flag", color: .btText2,
                     text: reasonShort != nil ? "HIDDEN · YOU REPORTED THIS FOR \(reasonUpper)" : "HIDDEN · YOU REPORTED THIS")

            if let bodyText {
                Text("\"\(bodyText)\"")
                    .font(BTFont.body(size: 12))
                    .strikethrough()
                    .foregroundStyle(Color.btText3)
                    .lineLimit(2)
                    .padding(.top, BTSpacing.sm)
            }

            Button { onShowAnyway?() } label: {
                Text("Show anyway")
                    .font(BTFont.bodyBold(size: 11.5))
                    .tracking(0.6)
                    .foregroundStyle(Color.btLime)
            }
            .buttonStyle(.plain)
            .padding(.top, BTSpacing.sm)
        }
    }

    // MARK: - Under review

    private var underReviewView: some View {
        card(border: Color.btWarn.opacity(0.35), fill: Color.btWarn.opacity(0.06)) {
            labelRow(icon: "exclamationmark.circle", color: .btWarn,
                     text: "UNDER REVIEW · \(reportCount) REPORTS")
            Text("A post of yours is under review. If it doesn't break our guidelines, it'll be back up shortly. We'll let you know either way.")
                .font(BTFont.body(size: 12.5))
                .foregroundStyle(Color.btText2)
                .lineSpacing(3)
                .padding(.top, BTSpacing.sm)
            if let bodyText { quote(bodyText, lines: 2) }
        }
    }

    // MARK: - Removed

    private var removedView: some View {
        card(border: Color.btPink.opacity(0.35), fill: Color.btPink.opacity(0.06)) {
            labelRow(icon: "exclamationmark.triangle", color: .btPink,
                     text: reasonShort != nil ? "REMOVED · \(reasonUpper)" : "REMOVED")
            Text("This post was removed for \(reasonShort ?? "a guideline violation"). This counts as a warning.")
                .font(BTFont.body(size: 12.5))
                .foregroundStyle(Color.btText2)
                .lineSpacing(3)
                .padding(.top, BTSpacing.sm)
            if let bodyText { quote(bodyText, lines: 3) }

            if appealed {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.btText2)
                    Text("Appeal submitted · awaiting review")
                        .font(BTFont.bodyMedium(size: 11.5))
                        .foregroundStyle(Color.btText2)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.btSurface2)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.btLine, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, BTSpacing.md)
            } else {
                Button { onAppeal?() } label: {
                    Text("Appeal →")
                        .font(BTFont.bodyBold(size: 12))
                        .foregroundStyle(Color.btOnAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.btLime)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.top, BTSpacing.md)
            }
        }
    }

    // MARK: - Shared pieces

    private func labelRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text(text)
                .font(BTFont.monoBold(size: 9.5))
                .tracking(1.6)
                .foregroundStyle(color)
        }
    }

    private func quote(_ text: String, lines: Int) -> some View {
        Text("\"\(text)\"")
            .font(BTFont.body(size: 12))
            .italic()
            .foregroundStyle(Color.btText3)
            .lineLimit(lines)
            .padding(.top, BTSpacing.sm)
    }

    private func card<Content: View>(border: Color, fill: Color, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Compact reply-thread variant — a slim inline row, no body.
struct ReplyTombstone: View {
    var reasonShort: String?
    var onShowAnyway: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "flag")
                .font(.system(size: 11))
                .foregroundStyle(Color.btText2)
            Text(reasonShort != nil ? "reply hidden · you reported this for \(reasonShort!)" : "reply hidden · you reported this")
                .font(BTFont.body(size: 11.5))
                .foregroundStyle(Color.btText2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onShowAnyway) {
                Text("show")
                    .font(BTFont.bodyBold(size: 11.5))
                    .foregroundStyle(Color.btLime)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.lg) {
            Tombstone(variant: .reporter, reasonShort: "hate speech",
                      bodyText: "some reported post text", onShowAnyway: {})
            Tombstone(variant: .underReview, bodyText: "a post of yours")
            Tombstone(variant: .removed, reasonShort: "hate speech", onAppeal: {})
            Tombstone(variant: .removed, reasonShort: "hate speech", appealed: true)
            ReplyTombstone(reasonShort: "spam", onShowAnyway: {})
        }
        .padding()
    }
}
