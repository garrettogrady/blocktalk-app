import SwiftUI

struct PostCard: View {
    let post: Post
    var isPreview: Bool = false
    var pending: Bool = false
    var username: String = "BlockTalker"
    var userNumber: Int = 0
    var homeShortCode: String?
    var cornerName: String?

    @Environment(AppState.self) private var appState
    @Environment(ModerationStore.self) private var moderation
    @State private var showReport = false
    @State private var enrolled = false
    @State private var toastMessage = ""
    @State private var toastIcon = "bell.fill"
    @State private var toastVisible = false

    // Prefer the embedded author from the fetch; fall back to passed params
    private var displayUsername: String { post.author?.username ?? username }
    private var displayNumber: Int { post.author?.userNumber ?? userNumber }
    private var displayHome: String? { post.author?.home?.shortCode ?? homeShortCode }

    var body: some View {
        // Reporter-side hide: a post you reported collapses to a tombstone
        if !isPreview && moderation.isHidden(post.id) {
            Tombstone(
                variant: .reporter,
                reasonShort: moderation.reasonShort(post.id),
                bodyText: post.text,
                onShowAnyway: { moderation.toggleShowAnyway(post.id) }
            )
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.sm)
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Meta row
            metaRow

            // NOTE (§8, pending backend seed): street-comment 80px map snippet and
            // the link-preview card render here in the mock; both need pin coords /
            // linkPreview data from the backend, so they're wired in a later chunk.

            // Optional image — renders ABOVE the body to match the mock
            if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(BTRadius.md)
                    case .failure:
                        EmptyView()
                    default:
                        RoundedRectangle(cornerRadius: BTRadius.md)
                            .fill(Color.btSurface2)
                            .frame(height: 120)
                            .overlay(ProgressView().tint(Color.btText3))
                    }
                }
            }

            // Body text
            Text(post.text)
                .font(BTFont.body(size: 13))
                .foregroundStyle(Color.btText)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)

            // Action row (hidden in preview + pending modes)
            if !isPreview && !pending {
                actionRow

                if toastVisible {
                    enrollmentToast
                        .transition(.opacity)
                }
            }
        }
        .padding(BTSpacing.lg)
        .opacity(pending ? 0.7 : 1)
        .background(
            pending
                ? Color.btWarn.opacity(0.03)
                : (post.isStreetComment ? Color.btLime.opacity(0.04) : Color.btBg)
        )
        .overlay(alignment: .leading) {
            // Street comment variant: 3px lime left border
            if post.isStreetComment {
                Rectangle()
                    .fill(Color.btLime)
                    .frame(width: 3)
            }
        }
        .sheet(isPresented: $showReport) {
            ReportModalView(postId: post.id) { short in
                moderation.report(postId: post.id, reasonShort: short)
                showToast("reported for \(short) · we'll review", icon: "flag.fill")
            }
        }
    }

    // MARK: - Meta Row

    private var metaRow: some View {
        HStack(spacing: 6) {
            Text("@\(displayUsername)")
                .font(BTFont.bodySemibold(size: 11))
                .foregroundStyle(Color.btText)

            Text("#\(displayNumber.formatted(.number))")
                .font(BTFont.monoBold(size: 11))
                .foregroundStyle(Color.btLime)

            if let shortCode = displayHome {
                HomeBadge(shortCode: shortCode)
            }

            // Corner badge only on street comments with a resolved corner name
            if post.isStreetComment, let corner = cornerName {
                PinBadge(cornerName: corner)
            }

            if pending {
                pendingPill
            } else if let createdAt = post.createdAt {
                Text("·")
                    .foregroundStyle(Color.btText3)
                Text(timeAgo(createdAt))
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: 6) {
            // Vote pills
            VotePills(
                score: post.score,
                onUpvote: {},
                onDownvote: {}
            )

            // Bell — enroll toggle + haptic + toast
            actionButton(
                systemName: enrolled ? "bell.fill" : "bell",
                active: enrolled,
                activeColor: .btLime,
                action: toggleBell
            )

            // Share — native share sheet
            actionButton(systemName: "square.and.arrow.up") {
                ShareHelper.sharePost(post)
            }

            // Flag (hidden on own posts; filled+pink once reported)
            if appState.currentUser?.id != post.userId {
                if moderation.isReported(post.id) {
                    actionButton(systemName: "flag.fill", active: true, activeColor: .btPink) {}
                } else {
                    actionButton(systemName: "flag") {
                        showReport = true
                    }
                }
            }

            Spacer(minLength: 0)

            // Reply count — "N replies", no icon
            (Text("\(post.replyCount)").foregroundStyle(Color.btText)
                + Text(" replies").foregroundStyle(Color.btText2))
                .font(BTFont.monoBold(size: 11))
        }
    }

    private func actionButton(systemName: String, active: Bool = false, activeColor: Color = .btText2, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(active ? activeColor : Color.btText2)
                .frame(width: 30, height: 30)
                .background(active ? activeColor.opacity(0.12) : Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.sm)
                        .stroke(active ? activeColor.opacity(0.45) : Color.btLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
        }
        .buttonStyle(.plain)
    }

    private func toggleBell() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        enrolled.toggle()
        showToast(
            enrolled ? "you're in — we'll ping you when something moves"
                     : "you're out — we'll leave this one alone",
            icon: enrolled ? "bell.fill" : "bell.slash"
        )
    }

    private func showToast(_ message: String, icon: String) {
        toastMessage = message
        toastIcon = icon
        withAnimation { toastVisible = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toastVisible = false }
        }
    }

    // MARK: - Enrollment Toast

    private var enrollmentToast: some View {
        HStack(spacing: BTSpacing.xs) {
            Image(systemName: toastIcon)
                .font(.system(size: 11))
                .foregroundStyle(Color.btLime)
            Text(toastMessage)
                .font(BTFont.bodyMedium(size: 11))
                .foregroundStyle(Color.btText)
        }
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, 5)
        .background(Color.btLime.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.sm)
                .stroke(Color.btLime.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
    }

    private var pendingPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 9))
            Text("PENDING · sends when online")
                .font(BTFont.monoBold(size: 9))
                .tracking(0.6)
        }
        .foregroundStyle(Color.btWarn)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.btWarn.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: BTRadius.sm).stroke(Color.btWarn.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
    }

    // MARK: - Time Ago

    private func timeAgo(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        PostCard(
            post: Post(
                id: UUID(),
                userId: UUID(),
                neighborhoodId: UUID(),
                text: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter. no regrets.",
                isDailyPrompt: false,
                score: 42,
                replyCount: 7,
                reportCount: 0,
                status: .live
            ),
            username: "streetrat",
            userNumber: 4827,
            homeShortCode: "LES"
        )
        .environment(AppState())
        .environment(ModerationStore())
    }
}
