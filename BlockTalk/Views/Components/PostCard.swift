import MapKit
import SwiftUI

struct PostCard: View {
    let post: Post
    var isPreview: Bool = false
    var pending: Bool = false
    /// Suppress the inline street mini-map (used in Pin Detail, which already
    /// shows a full-size map of the same corner up top).
    var showStreetMap: Bool = true
    var username: String = "BlockTalker"
    var userNumber: Int = 0
    var homeShortCode: String?
    var cornerName: String?

    @Environment(AppState.self) private var appState
    @Environment(ModerationStore.self) private var moderation
    @Environment(LocalContentStore.self) private var localContent
    @State private var showReport = false
    @State private var showAppeal = false
    @State private var appealed = false
    @State private var enrolled = false
    @State private var toastMessage = ""
    @State private var toastIcon = "bell.fill"
    @State private var toastVisible = false

    // Prefer the embedded author from the fetch; fall back to passed params
    private var displayUsername: String { post.author?.username ?? username }
    private var displayNumber: Int { post.author?.userNumber ?? userNumber }
    private var displayHome: String? { post.author?.home?.shortCode ?? homeShortCode }
    private var streetPin: Pin? {
        guard let id = post.pinId else { return nil }
        // Session-created pins first, then the bundled sample corners.
        return localContent.pin(id: id) ?? Pin.samples.first { $0.id == id }
    }

    private var hasPhoto: Bool { !(post.imageUrl ?? "").isEmpty }

    /// Route 2 color coding: a street comment tagged to a business is house-blue
    /// ("a place"); a plain corner comment stays lime.
    private var isBusinessTagged: Bool { streetPin?.placeName != nil }
    private var tagColor: Color { isBusinessTagged ? Color.btHouse : Color.btLime }

    /// Your own posts can't be reported. Matches by author id, and also treats
    /// anything you created this session (in the local store) as yours.
    private var isOwnPost: Bool {
        if let uid = appState.currentUser?.id, uid == post.userId { return true }
        return localContent.posts.contains { $0.id == post.id }
    }

    /// Lime location pill overlaid on a street comment's photo (bottom-left).
    /// Prefers a tagged business name over the raw corner.
    @ViewBuilder private var photoPinChip: some View {
        if post.isStreetComment,
           let label = streetPin?.placeName ?? streetPin?.cornerName ?? cornerName {
            HStack(spacing: 4) {
                Image(systemName: streetPin?.placeName != nil ? (streetPin?.placeSymbol ?? "mappin.circle.fill") : "mappin.circle.fill")
                    .font(.system(size: 11))
                Text(label).font(BTFont.monoBold(size: 10)).tracking(0.3)
            }
            .foregroundStyle(Color.btBg)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, 5)
            .background(tagColor)
            .clipShape(Capsule())
            .padding(BTSpacing.sm)
        }
    }

    /// Meta-row chip for a street comment tagged to a business (name only, no
    /// logo — nominative identification, comment-language not review-language).
    private func businessChip(_ name: String, symbol: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 9))
            Text(name).font(BTFont.monoBold(size: 10)).lineLimit(1)
        }
        .foregroundStyle(Color.btHouse)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.btHouse.opacity(0.12))
        .overlay(Capsule().stroke(Color.btHouse.opacity(0.32), lineWidth: 1))
        .clipShape(Capsule())
    }

    var body: some View {
        Group {
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
            } else if !isPreview && post.status == .removed {
                // Your post was removed — appeal it.
                Tombstone(variant: .removed, reasonShort: "hate speech",
                          bodyText: post.text, appealed: appealed,
                          onAppeal: { showAppeal = true })
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.vertical, BTSpacing.sm)
            } else if !isPreview && post.status == .underReview {
                Tombstone(variant: .underReview, bodyText: post.text)
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.vertical, BTSpacing.sm)
            } else {
                cardContent
            }
        }
        .sheet(isPresented: $showAppeal, onDismiss: { appealed = true }) {
            AppealView(removedPostText: post.text, violationReason: "hate speech", alreadyAppealed: appealed)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Meta row
            metaRow

            // Street-comment map snippet (where the comment was dropped) — core
            // "this exact corner" context. Suppressed when the post has a photo:
            // the photo becomes the hero and the location shows as a pin chip on
            // it instead (a stacked map + photo would be too tall).
            if let pin = streetPin, !isPreview, showStreetMap, !hasPhoto {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: pin.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0019)
                )), interactionModes: []) {
                    Annotation("", coordinate: pin.coordinate) {
                        // Business-tagged pins carry their category glyph (dumbbell,
                        // fork, cup…) so the map reads by type — matches the map tab.
                        ZStack {
                            Circle().fill(tagColor.opacity(0.25))
                                .frame(width: isBusinessTagged ? 30 : 18, height: isBusinessTagged ? 30 : 18)
                            Circle().fill(tagColor)
                                .frame(width: isBusinessTagged ? 20 : 9, height: isBusinessTagged ? 20 : 9)
                                .overlay {
                                    if isBusinessTagged, let sym = streetPin?.placeSymbol {
                                        Image(systemName: sym)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color.btBg)
                                    }
                                }
                                .overlay(Circle().stroke(Color.btBg, lineWidth: 1.5))
                        }
                    }
                }
                .frame(height: 150)
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .colorScheme(.dark)
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
                .allowsHitTesting(false)
            }

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
                            // Street comment + photo: location badge on the photo
                            // so "where" stays unmistakable without a second map.
                            .overlay(alignment: .bottomLeading) { photoPinChip }
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

            // A tagged business takes the place of the corner name; otherwise
            // the corner badge (street comments only).
            if let place = streetPin?.placeName {
                businessChip(place, symbol: streetPin?.placeSymbol ?? "mappin.circle.fill")
            } else if let corner = streetPin?.cornerName ?? cornerName {
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

            // Flag (hidden on your own posts — you can't report yourself; filled+pink once reported)
            if !isOwnPost {
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
        // Notification-style buzz (like a received text) for enroll/de-enroll,
        // mirroring the Expo app's Vibration.vibrate(30) feedback.
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        enrolled.toggle()
        showToast(
            enrolled ? "Notifications on. We'll let you know about new replies."
                     : "Notifications off for this post.",
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
