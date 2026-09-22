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
    @Environment(ContentEditStore.self) private var edits
    @State private var showReport = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showHistory = false
    @State private var showAppeal = false
    @State private var showPushAsk = false
    @State private var showSettingsAlert = false
    @State private var toastMessage = ""
    @State private var toastIcon = "bell.fill"
    @State private var toastVisible = false

    /// The post as it reads right now: the server row plus any edit or delete you
    /// made this session (so every list updates without a refetch).
    private var shown: Post { edits.apply(post) }

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

    /// Live tier from the embedded author. For your own posts the embedded aura was
    /// captured when the list loaded and can lag a level-up; aura only ever goes up,
    /// so the larger of that and your current profile value is always the right one.
    /// Anyone else's post without an author shows no badge rather than a made-up level.
    private var authorLevel: AuthorityLevel? {
        let embedded = post.author?.aura
        if isOwnPost, let mine = appState.currentUser?.aura {
            return Authority.level(for: max(mine, embedded ?? 0))
        }
        return embedded.map(Authority.level(for:))
    }

    /// Whether the meta row carries a place chip (corner or business). Decided by
    /// post type, never by measured width, so the layout never reshuffles.
    private var hasPlaceChip: Bool {
        (streetPin?.placeName != nil && !carriesBusinessOverlay)
            || (!isBusinessTagged && (streetPin?.cornerName ?? cornerName) != nil)
    }

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
            if edits.isHardDeleted(postId: post.id) {
                // Gone. The list refetches on its next load; until then, nothing.
                EmptyView()
            } else if !isPreview && shown.status == .deleted {
                // Deleted by author but replies survive. The tombstone only shows in
                // Post Detail (expandedText); feeds drop deleted posts on refresh.
                if expandedText {
                    Tombstone(variant: .deleted, replyCount: post.replyCount)
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.vertical, BTSpacing.sm)
                } else {
                    EmptyView()
                }
            // Reporter-side hide: a post you reported collapses to a tombstone
            } else if !isPreview && moderation.isHidden(post.id) {
                Tombstone(
                    variant: .reporter,
                    reasonShort: moderation.reasonShort(post.id),
                    bodyText: post.text,
                    onShowAnyway: { moderation.toggleShowAnyway(post.id) }
                )
                .padding(.horizontal, BTSpacing.lg)
                .padding(.vertical, BTSpacing.sm)
            } else if !isPreview && post.status == .removed {
                // Your post was removed — appeal it (once). Show the actual moderation
                // reason when the backend recorded one; otherwise a neutral fallback
                // (never a hardcoded "harassment", which was wrong for most removals).
                Tombstone(variant: .removed, reasonShort: post.moderationReason,
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
            AppealView(postId: post.id, removedPostText: post.text,
                       violationReason: post.moderationReason ?? "a guideline violation",
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
                            // Fill the card width, but cap the height so a tall photo
                            // doesn't take over the screen — no crop, no distortion.
                            // Left-aligned so a capped (narrower) photo hugs the edge.
                            .frame(maxHeight: 380)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
            Text(shown.text)
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
        .sheet(isPresented: $showEdit) {
            EditTextSheet(title: "Edit post", limit: ComposeViewModel.postLimit, original: shown.text) { newText in
                await saveEdit(newText)
            }
        }
        .sheet(isPresented: $showHistory) {
            EditHistorySheet(original: shown.originalText ?? "", current: shown.text,
                             originalAt: post.createdAt, editedAt: shown.editedAt)
        }
        .alert("Delete this post?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { Task { await performDelete() } }
        } message: {
            // Naming the surviving reply count heads off "I deleted it, why is it still there."
            if post.replyCount > 0 {
                Text("Your text will be removed. The \(post.replyCount) \(post.replyCount == 1 ? "reply" : "replies") underneath it will stay. Other people wrote those.")
            } else {
                Text("It'll be gone from the feed, the map and search. This can't be undone.")
            }
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

    /// One row for a plain post; a pinned post moves the home badge and place chip
    /// to a second row. Time lives in the action row (see actionRow).
    private var metaRow: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            HStack(spacing: 6) {
                Text("@\(displayUsername)")
                    .font(BTFont.bodySemibold(size: 11))
                    .foregroundStyle(authorLevel?.tier.color ?? Color.btText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Grey, not lime: a lime number beside a lime Blocktalker username
                // would read as two signals meaning different things.
                Text("#\(displayNumber.formatted(.number))")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)

                if let level = authorLevel {
                    AuthorityBadge(level: level)
                }

                if !hasPlaceChip, let shortCode = displayHome {
                    HomeBadge(shortCode: shortCode)
                }

                if pending && !hasPlaceChip {
                    pendingPill
                }

                Spacer(minLength: 0)
            }

            if hasPlaceChip {
                HStack(spacing: 6) {
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
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }


    // MARK: - Action Row

    /// Persist a vote. VotePills owns the optimistic UI; this writes the set.
    /// [Backend: clear/switch handled server-side — handoff workstream 1.]
    private func castVote(_ direction: Int) {
        guard let userId = appState.currentUser?.id else { return }
        Task {
            do {
                try await PostService().vote(postId: post.id, userId: userId, direction: direction)
            } catch {
                // Only a rate limit is worth interrupting for; other failures stay quiet.
                if let message = RateLimit.message(for: error) {
                    showToast(message, icon: "exclamationmark.triangle")
                }
            }
        }
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
            } else if post.status == .live {
                // Your own post: edit the text, or delete it.
                ownerMenu
            }

            Spacer(minLength: 0)

            // "4m · edited · 7 replies": age moved here from the meta row, no icon.
            // "edited" is a dotted-underline tap target for the original-vs-now sheet.
            if shown.editedAt != nil {
                Button { showHistory = true } label: { timestampRun }
                    .buttonStyle(.plain)
            } else {
                timestampRun
            }
        }
    }

    private var timestampRun: some View {
        var run = Text(post.createdAt.map { RelativeTime.short(since: $0) + " · " } ?? "")
            .font(BTFont.mono(size: 11))
            .foregroundStyle(Color.btText3)
        if shown.editedAt != nil {
            run = run
                + Text("edited").font(BTFont.mono(size: 11)).foregroundStyle(Color.btText3)
                    .underline(true, pattern: .dot, color: Color.btLine2)
                + Text(" · ").font(BTFont.mono(size: 11)).foregroundStyle(Color.btText3)
        }
        return (run
             + Text("\(post.replyCount)").font(BTFont.monoBold(size: 11)).foregroundStyle(Color.btText)
             + Text(" replies").font(BTFont.monoBold(size: 11)).foregroundStyle(Color.btText2))
            .lineLimit(1)
            .fixedSize()
    }

    /// Ellipsis box matching the other action buttons; owner only.
    private var ownerMenu: some View {
        Menu {
            Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Delete", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13))
                .foregroundStyle(Color.btText2)
                .frame(width: 30, height: 30)
                .background(Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.sm)
                        .stroke(Color.btLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
        }
        .accessibilityLabel("More")
    }

    // MARK: - Edit / Delete

    /// Returns an error message, or nil on success.
    private func saveEdit(_ newText: String) async -> String? {
        do {
            let result = try await ContentEditingService().editPost(id: post.id, text: newText)
            edits.recordEdit(postId: post.id, .init(
                text: result.text ?? newText,
                originalText: result.originalText,
                editedAt: (result.marked ?? false) ? Date() : shown.editedAt,
                editCount: result.editCount
            ))
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func performDelete() async {
        do {
            let result = try await ContentEditingService().deletePost(id: post.id)
            switch result.outcome {
            case .hard: edits.recordHardDelete(postId: post.id)
            case .tombstone, .none: edits.recordTombstone(postId: post.id)
            }
        } catch {
            showToast(error.localizedDescription, icon: "exclamationmark.triangle")
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
        .environment(ContentEditStore())
    }
}
