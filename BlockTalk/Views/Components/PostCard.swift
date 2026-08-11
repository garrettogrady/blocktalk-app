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
    /// Detail view passes true → show full text + the standard layout (the feed's
    /// clamped place-split is a list presentation, not a detail one).
    var expandedText: Bool = false

    @Environment(AppState.self) private var appState
    @Environment(ModerationStore.self) private var moderation
    @Environment(LocalContentStore.self) private var localContent
    @Environment(PinStore.self) private var pinStore
    @Environment(NotificationStore.self) private var notifications
    @Environment(EnrollmentStore.self) private var enrollments
    @State private var showReport = false
    @State private var showAppeal = false
    @State private var showPushAsk = false
    @State private var showSettingsAlert = false
    @State private var toastMessage = ""
    @State private var toastIcon = "bell.fill"
    @State private var toastVisible = false

    // Prefer the embedded author from the fetch; fall back to passed params
    private var displayUsername: String { post.author?.username ?? username }
    private var displayNumber: Int { post.author?.userNumber ?? userNumber }
    private var displayHome: String? { post.author?.home?.shortCode ?? homeShortCode }
    private var streetPin: Pin? {
        guard let id = post.pinId else { return nil }
        // Your own session pin first (has the business tag before the DB does),
        // then the fetched DB cache — so EVERY street comment renders its corner
        // + map, not just ones you dropped this session.
        return localContent.pin(id: id) ?? pinStore.pin(id: id)
    }

    private var hasPhoto: Bool { !(post.imageUrl ?? "").isEmpty }

    /// Route 2 color coding: a street comment tagged to a business is house-blue
    /// ("a place"); a plain corner comment stays lime.
    private var isBusinessTagged: Bool { streetPin?.placeName != nil }
    private var tagColor: Color { isBusinessTagged ? Color.btHouse : Color.btLime }

    /// Whether the full-width map snippet is showing (street comment, not a photo).
    private var showsMapSnippet: Bool {
        streetPin != nil && !isPreview && showStreetMap && !hasPhoto
    }
    /// A business-tagged comment names the place ON its map/photo — so the meta-row
    /// business chip is redundant whenever a visual is present to carry the label.
    private var carriesBusinessOverlay: Bool {
        isBusinessTagged && (showsMapSnippet || hasPhoto)
    }

    /// Your own posts can't be reported. Matches by author id, and also treats
    /// anything you created this session (in the local store) as yours.
    private var isOwnPost: Bool {
        if let uid = appState.currentUser?.id, uid == post.userId { return true }
        return localContent.posts.contains { $0.id == post.id }
    }

    /// Business name across the TOP of the street comment's map (or photo) on a
    /// soft dark-to-transparent fade — prominent + always readable, without a hard
    /// pill or altering the map itself. Overlay it BEFORE the container's clip so
    /// the banner's top corners follow the rounded rect.
    @ViewBuilder private var businessMapBanner: some View {
        if let name = streetPin?.placeName {
            VStack(alignment: .leading, spacing: 3) {
                // Row 1: the business name.
                Text(name)
                    .font(BTFont.bodyBold(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                // Row 2: house-blue type icon + label.
                HStack(spacing: 4) {
                    Image(systemName: streetPin?.placeSymbol ?? "mappin.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(streetPin?.placeCategory ?? "Place")
                        .font(BTFont.mono(size: 10))
                }
                .foregroundStyle(Color.btHouse)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: BTRadius.sm))
            .padding(BTSpacing.sm)   // inset from the map's top-left corner
        }
    }

    /// Lime corner chip on a PLAIN corner comment's photo (bottom-left). A
    /// business-tagged photo uses the top banner instead.
    @ViewBuilder private var photoPinChip: some View {
        if !isBusinessTagged, post.isStreetComment,
           let label = streetPin?.cornerName ?? cornerName {
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill").font(.system(size: 11))
                Text(label).font(BTFont.monoBold(size: 10)).tracking(0.3)
            }
            .foregroundStyle(Color.btBg)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, 5)
            .background(Color.btLime)
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
                // Your post was removed — appeal it (once).
                Tombstone(variant: .removed, reasonShort: "harassment",
                          bodyText: post.text, appealed: moderation.hasAppealed(post.id),
                          onAppeal: { if !moderation.hasAppealed(post.id) { showAppeal = true } })
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
        .sheet(isPresented: $showAppeal) {
            AppealView(postId: post.id, removedPostText: post.text, violationReason: "Harassment",
                       alreadyAppealed: moderation.hasAppealed(post.id),
                       onSubmitted: {
                           moderation.markAppealed(post.id)
                           notifications.add(kind: "moderation", title: "Appeal submitted",
                                             preview: "We got your appeal. A human will review within 48 hours.",
                                             relatedPostId: post.id)
                       })
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
                )), interactionModes: expandedText ? .zoom : []) {
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
                // Business-tagged: a top-left label naming the place (name over its
                // type). The map snippet itself stays identical to a plain corner's.
                .overlay(alignment: .topLeading) {
                    if isBusinessTagged { businessMapBanner }
                }
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
                // In detail, allow pinch-zoom so you can zoom in until street names
                // appear; in the feed the snippet stays static (the card owns the tap).
                .allowsHitTesting(expandedText)
            }

            // Optional image — renders ABOVE the body to match the mock
            if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        // Fit (not fill) so the full photo shows on the card, matching
                        // the compose preview — what you post is what you see. Capped
                        // height keeps a tall photo from taking over the feed.
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .frame(maxWidth: .infinity, alignment: .center)
                            // Business-tagged → the top-left name label; a plain
                            // corner comment → the lime corner chip bottom-left.
                            .overlay(alignment: .topLeading) {
                                if isBusinessTagged { businessMapBanner }
                            }
                            .overlay(alignment: .bottomLeading) { photoPinChip }
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
                : isBusinessTagged
                    ? Color.btHouse.opacity(0.05)   // "a place" → house-blue tint
                    : (post.isStreetComment ? Color.btLime.opacity(0.04) : Color.btBg)
        )
        .overlay(alignment: .leading) {
            // Street comment variant: 3px left border — house-blue for a tagged
            // business ("a place"), lime for a plain corner comment.
            if post.isStreetComment {
                Rectangle()
                    .fill(isBusinessTagged ? Color.btHouse : Color.btLime)
                    .frame(width: 3)
            }
        }
        .sheet(isPresented: $showPushAsk) {
            PushPermissionSheet()
        }
        .alert("Notifications are off", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Turn on notifications in Settings to get replies on this post.")
        }
        .sheet(isPresented: $showReport) {
            ReportModalView(postId: post.id) { short in
                moderation.report(postId: post.id, reasonShort: short)
                showToast("reported for \(short) · we'll review", icon: "flag.fill")
                notifications.add(kind: "moderation", title: "Report received",
                                  preview: "Thanks — we're reviewing this post for \(short).",
                                  relatedPostId: post.id)
            }
        }
    }

    // MARK: - Meta Row

    private var metaRow: some View {
        HStack(spacing: 6) {
            Text("@\(displayUsername)")
                .font(BTFont.bodySemibold(size: 11))
                .foregroundStyle(Color.btText)
                .lineLimit(1)
                .truncationMode(.tail)

            Text("#\(displayNumber.formatted(.number))")
                .font(BTFont.monoBold(size: 11))
                .foregroundStyle(Color.btLime)

            if let shortCode = displayHome {
                HomeBadge(shortCode: shortCode)
            }

            // A tagged business shows its chip only when no map/photo is present to
            // carry the blue place label (else it's redundant). Plain corner
            // comments show the corner badge.
            if let place = streetPin?.placeName, !carriesBusinessOverlay {
                businessChip(place, symbol: streetPin?.placeSymbol ?? "mappin.circle.fill")
            } else if !isBusinessTagged, let corner = streetPin?.cornerName ?? cornerName {
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

    /// Persist a vote. VotePills owns the optimistic UI; this writes the set.
    /// [Backend: clear/switch handled server-side — handoff workstream 1.]
    private func castVote(_ direction: Int) {
        guard let userId = appState.currentUser?.id else { return }
        Task { try? await PostService().vote(postId: post.id, userId: userId, direction: direction) }
        Analytics.voteCast(direction: direction)
    }

    private func clearVote() {
        guard let userId = appState.currentUser?.id else { return }
        Task { try? await PostService().removeVote(postId: post.id, userId: userId) }
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            // Vote pills
            VotePills(
                score: post.score,
                upvoteCount: post.upvoteCount,
                downvoteCount: post.downvoteCount,
                onUpvote: { castVote(1) },
                onDownvote: { castVote(-1) },
                onClear: { clearVote() }
            )

            // Bell — enroll toggle + haptic + toast
            actionButton(
                systemName: enrollments.isEnrolled(post.id) ? "bell.fill" : "bell",
                active: enrollments.isEnrolled(post.id),
                activeColor: .btLime,
                action: toggleBell
            )

            // Share — native share sheet
            actionButton(systemName: "square.and.arrow.up") {
                ShareHelper.sharePost(post)
                Analytics.shareTapped()
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
        guard let userId = appState.currentUser?.id else { return }
        let wasEnrolled = enrollments.isEnrolled(post.id)

        // Unenrolling always works regardless of push permission
        if wasEnrolled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            enrollments.unenroll(userId: userId, postId: post.id)
            Analytics.bellEnrolled(enrolled: false)
            showToast("Notifications off for this post.", icon: "bell.slash")
            return
        }

        // Enrolling: check push permission first
        switch pushManager.permissionState {
        case .undetermined:
            showPushAsk = true
        case .denied:
            showSettingsAlert = true
        case .granted:
            break
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        enrollments.enroll(userId: userId, postId: post.id)
        Analytics.bellEnrolled(enrolled: true)
        showToast("Notifications on. We'll let you know about new replies.", icon: "bell.fill")
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
                upvoteCount: 45,
                downvoteCount: 3,
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
        .environment(EnrollmentStore())
    }
}
