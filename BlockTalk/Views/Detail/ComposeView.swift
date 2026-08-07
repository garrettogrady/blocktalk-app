import CoreLocation
import MapKit
import PhotosUI
import SwiftUI
import UIKit

struct ComposeView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @Environment(OfflineStore.self) private var offline
    @Environment(LocalContentStore.self) private var localContent
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ComposeViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showAttachDialog = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pinCleared = false
    @State private var submitError: String?
    // Optional business the street comment is tagged to (Apple Maps POI).
    @State private var taggedPlace: TaggedPlace?
    @State private var showPlacePicker = false
    @FocusState private var textFocused: Bool

    /// Pin can be toggled off locally (the ≡ footer button) without closing.
    private var effectivePin: CLLocationCoordinate2D? {
        pinCleared ? nil : pinDropLocation
    }
    /// Daily-prompt / NYC-wide compose locks its scope — no feed↔pin toggle
    private var canToggleMode: Bool { !nycWide }

    /// The neighborhood this post will be submitted to
    var postingNeighborhood: Neighborhood?
    /// If set, creates a pin at this location before posting
    var pinDropLocation: CLLocationCoordinate2D?
    /// Snapped corner name for the dropped pin (from the Map)
    var pinCornerName: String?
    /// NYC-wide daily-prompt compose (from the Daily Prompt Feed)
    var nycWide: Bool = false
    /// When answering the weekly prompt, the prompt this post responds to — so
    /// it's tagged with daily_prompt_id and shows up in the prompt's responses.
    var dailyPromptId: UUID?
    /// Pre-tagged business (search-first pin from the Map): seeds the tag so the
    /// post opens already pinned to the place (paired with pinDropLocation).
    var initialPlace: TaggedPlace?

    @State private var resolvedStreet: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        // Scope row
                        scopeRow

                        // Tag a business — street comments only
                        if effectivePin != nil {
                            tagPlaceRow
                        }

                        // Image preview — ABOVE the input, per the mock
                        if let image = viewModel.selectedImage {
                            ZStack(alignment: .topTrailing) {
                                // Fit (not fill) so the WHOLE photo is visible in the
                                // preview — the user should see exactly what they're
                                // posting, not a cropped middle slice. Capped height
                                // keeps a tall photo from dominating the compose screen.
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 280)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .cornerRadius(BTRadius.md)

                                Button {
                                    viewModel.selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.btText)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color.black.opacity(0.7)))
                                }
                                .buttonStyle(.plain)
                                .padding(BTSpacing.sm)
                            }
                        }

                        // Text editor — text flips pink on a hate-speech hit
                        TextEditor(text: $viewModel.text)
                            .font(BTFont.body(size: 16))
                            .foregroundStyle(viewModel.hateSpeechDetected ? Color.btPink : Color.btText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                            .focused($textFocused)
                            .overlay(alignment: .topLeading) {
                                if viewModel.text.isEmpty {
                                    Text(nycWide ? "Answer the prompt…" : "what's on your block?")
                                        .font(BTFont.body(size: 16))
                                        .foregroundStyle(Color.btText3)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }

                        // Hate-speech warning
                        if viewModel.hateSpeechDetected {
                            HStack(alignment: .top, spacing: BTSpacing.sm) {
                                Image(systemName: "exclamationmark.octagon")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.btPink)
                                Text("Watch your language. BlockTalk doesn't allow hate speech.")
                                    .font(BTFont.bodySemibold(size: 12.5))
                                    .foregroundStyle(Color.btPink)
                            }
                            .padding(BTSpacing.md)
                            .background(Color.btPink.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: BTRadius.md)
                                    .stroke(Color.btPink.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                        }
                    }
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.top, BTSpacing.md)
                }

                Divider().background(Color.btLine)

                bottomBar
            }
            .background(Color.btBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        appState.composeDraft = ""
                        dismiss()
                    }
                    .foregroundStyle(Color.btText2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submitPost() }
                        .font(BTFont.bodySemibold(size: 16))
                        .foregroundStyle(viewModel.canSubmit ? Color.btLime : Color.btMuted)
                        .disabled(!viewModel.canSubmit)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Couldn't post", isPresented: Binding(
                get: { submitError != nil },
                set: { if !$0 { submitError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(submitError ?? "")
            }
            .confirmationDialog("Add a photo", isPresented: $showAttachDialog, titleVisibility: .hidden) {
                Button("Take Photo") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) { showCamera = true }
                }
                Button("Choose from Library") { showLibrary = true }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(isPresented: $showLibrary, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                        refocusInput()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    viewModel.selectedImage = image
                    refocusInput()
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showPlacePicker) {
                if let coord = effectivePin {
                    PlacePickerSheet(center: coord, selected: taggedPlace) { place in
                        taggedPlace = place
                    }
                    .presentationDetents([.large])
                }
            }
            .onAppear {
                // Rehydrate a stashed draft after the compose→map→compose round-trip
                if viewModel.text.isEmpty { viewModel.text = appState.composeDraft }
                textFocused = true
                // Search-first pin from the Map: open already tagged to the place.
                if taggedPlace == nil, let initialPlace { taggedPlace = initialPlace }
                // No snapped corner → reverse-geocode to nearest street (never show coords)
                if pinCornerName == nil, let coord = pinDropLocation { resolveStreet(coord) }
            }
            .onChange(of: viewModel.text) { _, newValue in
                appState.composeDraft = newValue
            }
        }
    }

    // MARK: - Tag a place (business)

    private var tagPlaceRow: some View {
        Button {
            textFocused = false
            showPlacePicker = true
        } label: {
            HStack(spacing: BTSpacing.sm) {
                if let place = taggedPlace {
                    Image(systemName: place.symbol)
                        .font(.system(size: 13)).foregroundStyle(Color.btHouse)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(place.name)
                            .font(BTFont.bodySemibold(size: 13)).foregroundStyle(Color.btText).lineLimit(1)
                        Text(place.category)
                            .font(BTFont.mono(size: 10)).foregroundStyle(Color.btText3)
                    }
                    Spacer(minLength: 0)
                    Button { taggedPlace = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16)).foregroundStyle(Color.btText3)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "storefront")
                        .font(.system(size: 14)).foregroundStyle(Color.btText2)
                    Text("Tag a business here")
                        .font(BTFont.bodySemibold(size: 13)).foregroundStyle(Color.btText2)
                    Text("optional")
                        .font(BTFont.mono(size: 9.5)).foregroundStyle(Color.btText3)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.btText3)
                }
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, BTSpacing.sm)
            .background(taggedPlace != nil ? Color.btHouse.opacity(0.08) : Color.btSurface)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(taggedPlace != nil ? Color.btHouse.opacity(0.35) : Color.btLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scope Row (regular / NYC-wide / pin)

    private var scopeRow: some View {
        HStack(spacing: BTSpacing.sm) {
            Circle().fill(Color.btLime).frame(width: 6, height: 6)
            scopeLabel
            Spacer(minLength: BTSpacing.sm)
            if let status = statusText {
                Text(status)
                    .font(BTFont.monoBold(size: 9.5))
                    .tracking(0.6)
                    .foregroundStyle(offline.isOffline ? Color.btWarn : Color.btLime)
            }
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.btSurface)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(Color.btLine, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }

    private var scopeLabel: some View {
        let base = Text("Posting to ").font(BTFont.body(size: 10.5)).foregroundColor(.btText2)
        if effectivePin != nil {
            let place = pinCornerName ?? resolvedStreet ?? "locating…"
            return base
                + Text("📍 DROPPED PIN").font(BTFont.bodySemibold(size: 10.5)).foregroundColor(.btText)
                + Text(" · ").font(BTFont.body(size: 10.5)).foregroundColor(.btText2)
                + Text(place).font(BTFont.bodySemibold(size: 10.5)).foregroundColor(.btLime)
        } else if nycWide {
            return base
                + Text("THIS WEEK'S PROMPT").font(BTFont.bodySemibold(size: 10.5)).foregroundColor(.btText)
                + Text(" · NYC-WIDE").font(BTFont.body(size: 10.5)).foregroundColor(.btText2)
        } else {
            return base
                + Text(resolvedNeighborhoodName).font(BTFont.bodySemibold(size: 10.5)).foregroundColor(.btText)
        }
    }

    private var statusText: String? {
        if effectivePin != nil { return nil }
        if offline.isOffline { return "📡 QUEUED LOCALLY" }
        return nycWide ? "▲ IN NYC" : "▲ IN-RANGE"
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: BTSpacing.md) {
            footerIcon("camera", active: viewModel.selectedImage != nil) { showAttachDialog = true }

            // Feed ↔ pin-drop mode toggle (hidden in daily-prompt / NYC-wide)
            if canToggleMode {
                if effectivePin != nil {
                    // ≡ — clear the pin, back to feed mode (no map round-trip)
                    footerIcon("line.3.horizontal") { clearPin() }
                } else {
                    // 📍 — stash draft, open Map in drop mode, reopen with the pin
                    footerIcon("mappin") { switchToPinMode() }
                }
            }

            Spacer()

            // Character counter — always visible
            Text("\(viewModel.characterCount.formatted()) / \(ComposeViewModel.postLimit.formatted())")
                .font(BTFont.monoBold(size: 11))
                .foregroundStyle(counterColor)
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.md)
    }

    private func footerIcon(_ systemName: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(active ? Color.btLime : Color.btText2)
                .frame(width: 32, height: 32)
                .background(active ? Color.btLime.opacity(0.1) : Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(active ? Color.btLime.opacity(0.3) : Color.btLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private var counterColor: Color {
        if viewModel.isOverLimit { return .btPink }
        if viewModel.characterCount >= ComposeViewModel.postWarnAt { return .btWarn }
        return .btText3
    }

    // MARK: - Helpers

    private func refocusInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { textFocused = true }
    }

    private func resolveStreet(_ coord: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, _ in
            if let p = placemarks?.first {
                resolvedStreet = p.thoroughfare.map { "near \($0)" } ?? p.name
            }
        }
    }

    private var resolvedPostingNeighborhoodId: UUID? {
        postingNeighborhood?.id
            ?? locationService.currentNeighborhood?.id
            ?? appState.currentUser?.homeNeighborhoodId
            ?? appState.viewingNeighborhood?.id
    }

    private var resolvedNeighborhoodName: String {
        postingNeighborhood?.name
            ?? locationService.currentNeighborhood?.name
            ?? "your neighborhood"
    }

    // MARK: - Submit

    private func submitPost() {
        #if DEBUG
        print("[Compose] submitPost called — canSubmit=\(viewModel.canSubmit) text=\(viewModel.text.prefix(30))… user=\(appState.currentUser?.id.uuidString.prefix(8) ?? "nil") session=\(appState.session != nil) neighborhood=\(resolvedPostingNeighborhoodId?.uuidString.prefix(8) ?? "nil")")
        #endif
        guard let userId = appState.currentUser?.id ?? appState.session?.user.id else {
            print("[Compose] BLOCKED: no authenticated user")
            return
        }
        guard let neighborhoodId = resolvedPostingNeighborhoodId else {
            print("[Compose] BLOCKED: no neighborhood resolved (physical=\(appState.physicalNeighborhood?.name ?? "nil"), viewing=\(appState.viewingNeighborhood?.name ?? "nil"), home=\(appState.currentUser?.homeNeighborhoodId?.uuidString.prefix(8) ?? "nil"))")
            return
        }

        // Offline: queue the post locally instead of sending (§16). Pin posts
        // queue too but hold the pin off the map until send.
        if offline.isOffline {
            let body = viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayPost = Post(
                id: UUID(), userId: userId, neighborhoodId: neighborhoodId,
                text: body, isDailyPrompt: dailyPromptId != nil, score: 0, upvoteCount: 0,
                downvoteCount: 0, replyCount: 0, reportCount: 0, status: .live, createdAt: Date()
            )
            let imageData = viewModel.selectedImage?.jpegData(compressionQuality: 0.8)
            let queued = OfflineStore.QueuedPost(
                post: displayPost,
                text: body,
                userId: userId,
                neighborhoodId: neighborhoodId,
                imageData: imageData,
                pinCoordinate: effectivePin,
                pinCornerName: pinCornerName ?? resolvedStreet,
                placeName: taggedPlace?.name,
                placeCategory: taggedPlace?.category,
                placeSymbol: taggedPlace?.symbol,
                isDailyPrompt: dailyPromptId != nil,
                dailyPromptId: dailyPromptId,
                queuedAt: Date()
            )
            offline.enqueue(queued)
            appState.composeDraft = ""
            appState.selectedTab = 0
            dismiss()
            return
        }

        // Embed the poster's identity so the created card renders correctly.
        let author = PostAuthor(
            username: appState.currentUser?.username,
            userNumber: appState.currentUser?.userNumber,
            home: .init(shortCode: appState.physicalNeighborhood?.shortCode
                        ?? appState.viewingNeighborhood?.shortCode ?? "LES")
        )

        Task {
            if let pinLocation = effectivePin {
                // Street comment: create the pin in Supabase first, then the post.
                let pinService = PinService()
                do {
                    var pin = try await pinService.createPin(
                        userId: userId,
                        coordinate: pinLocation,
                        cornerName: pinCornerName ?? resolvedStreet,
                        neighborhoodId: neighborhoodId,
                        placeName: taggedPlace?.name,
                        placeCategory: taggedPlace?.category,
                        placeSymbol: taggedPlace?.symbol
                    )
                    // The DB doesn't persist the business tag yet (needs 00004),
                    // so the returned pin has no place data. Stitch it on locally
                    // so your own tagged post reads blue this session.
                    if let place = taggedPlace {
                        pin.placeName = place.name
                        pin.placeCategory = place.category
                        pin.placeSymbol = place.symbol
                    }
                    if let post = await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId, author: author, pinId: pin.id) {
                        // Surface your just-placed post + its pin immediately, WITH
                        // the corner — the DB feed reload doesn't carry the pin's
                        // corner yet (see handoff: embed pin in the post payload).
                        localContent.add(post: post, pin: pin)
                        routeAfterPost()
                    } else {
                        submitError = viewModel.error ?? "Couldn't post. Try again."
                    }
                } catch {
                    print("Failed to create pin: \(error)")
                    submitError = "Couldn't drop your pin. Check your connection and try again."
                }
            } else {
                // Tag prompt answers so they appear in the prompt's response feed
                // and count toward "N answers".
                if dailyPromptId != nil { viewModel.isDailyPrompt = true }
                if let post = await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId, author: author, dailyPromptId: dailyPromptId) {
                    localContent.add(post: post)
                    routeAfterPost()
                } else {
                    submitError = viewModel.error ?? "Couldn't post. Try again."
                }
            }
        }
    }

    /// Post-submit routing follows the post type: pin → Map, feed → Feed,
    /// NYC-wide prompt answers skip routing.
    private func routeAfterPost() {
        appState.composeDraft = ""
        if effectivePin != nil {
            appState.selectedTab = 1
        } else if !nycWide {
            appState.selectedTab = 0
        }
        dismiss()
    }

    private func switchToPinMode() {
        appState.composeDraft = viewModel.text   // stash the draft
        appState.pendingPinPlacement = true       // Map will auto-enter drop mode
        appState.selectedTab = 1
        dismiss()
    }

    // MARK: - Pin helpers

    private func clearPin() {
        pinCleared = true
        taggedPlace = nil
    }
}

// MARK: - Tagged place (a business a street comment is attached to)

struct TaggedPlace: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: String
    let symbol: String
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    static func == (a: TaggedPlace, b: TaggedPlace) -> Bool { a.id == b.id }
}

// MARK: - Place search (shared by the compose sheet + the Map drop bar)

/// One Apple-Maps POI search used everywhere a user searches a business to pin.
enum PlaceSearch {
    static let excludedCategories: [MKPointOfInterestCategory] = [
        .publicTransport, .parking, .gasStation, .evCharger,
        .airport, .campground, .marina,
    ]

    /// Allowed places near `center`, within `radius`, closest first, capped.
    /// Empty `query` → nearby POIs only; otherwise a text search biased to here.
    static func places(query: String, center: CLLocationCoordinate2D,
                       radius: CLLocationDistance, maxResults: Int) async -> [TaggedPlace] {
        let q = query.trimmingCharacters(in: .whitespaces)

        // Nearby POIs are always fetched — they carry reliable categories that a
        // bare text hit can borrow for its icon.
        let poiReq = MKLocalPointsOfInterestRequest(center: center, radius: radius)
        poiReq.pointOfInterestFilter = MKPointOfInterestFilter(excluding: excludedCategories)
        let nearby = await items(poiReq)

        let raw: [MKMapItem]
        if q.isEmpty {
            raw = nearby
        } else {
            let textReq = MKLocalSearch.Request()
            textReq.naturalLanguageQuery = q
            textReq.region = MKCoordinateRegion(center: center,
                                                latitudinalMeters: radius * 2,
                                                longitudinalMeters: radius * 2)
            let textHits = await items(textReq)
            // Type-ahead: also match the already-fetched nearby places by name, so a
            // partial query ("ess") surfaces nearby hits ("Essex Market") instantly
            // instead of waiting for the whole-word match Apple's text search needs.
            // Nearby hits go first — they carry reliable categories (better icons)
            // and win dedup.
            let nearbyHits = nearby.filter {
                $0.name?.localizedCaseInsensitiveContains(q) ?? false
            }
            raw = nearbyHits + textHits
        }

        var seen = Set<String>()
        let places = raw.compactMap { toPlace($0, nearby: nearby) }.filter { p in
            // A place can appear in both lists — dedupe by name + rounded coordinate.
            let key = "\(p.name.lowercased())|\(Int(p.latitude * 1e4))|\(Int(p.longitude * 1e4))"
            return seen.insert(key).inserted
        }
        func dist(_ p: TaggedPlace) -> CLLocationDistance {
            CLLocation(latitude: center.latitude, longitude: center.longitude)
                .distance(from: CLLocation(latitude: p.latitude, longitude: p.longitude))
        }
        return Array(places.filter { dist($0) <= radius }
            .sorted { dist($0) < dist($1) }
            .prefix(maxResults))
    }

    private static func toPlace(_ item: MKMapItem, nearby: [MKMapItem]) -> TaggedPlace? {
        guard let name = item.name else { return nil }
        var (label, symbol) = placeDisplay(name: name, category: item.pointOfInterestCategory)
        if symbol == "mappin.circle.fill" {
            let here = item.placemark.coordinate
            if let match = nearby.first(where: { poi in
                poi.pointOfInterestCategory != nil &&
                CLLocation(latitude: here.latitude, longitude: here.longitude)
                    .distance(from: CLLocation(latitude: poi.placemark.coordinate.latitude,
                                               longitude: poi.placemark.coordinate.longitude)) < 25
            }) {
                (label, symbol) = placeCategoryDisplay(match.pointOfInterestCategory)
            }
        }
        let c = item.placemark.coordinate
        return TaggedPlace(name: name, category: label, symbol: symbol,
                           latitude: c.latitude, longitude: c.longitude)
    }

    private static func items(_ request: MKLocalSearch.Request) async -> [MKMapItem] {
        (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
    }
    private static func items(_ request: MKLocalPointsOfInterestRequest) async -> [MKMapItem] {
        (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
    }
}

/// Apple POI category → friendly label + SF Symbol.
func placeCategoryDisplay(_ c: MKPointOfInterestCategory?) -> (label: String, symbol: String) {
    guard let c else { return ("Place", "mappin.circle.fill") }

    // iOS 18 added ~33 fine-grained categories — Apple's own (accurate) classification.
    // Checked first so they win over the coarser base set below.
    if #available(iOS 18.0, *) {
        switch c {
        case .beauty:              return ("Beauty", "scissors")
        case .spa:                 return ("Spa", "sparkles")
        case .distillery:          return ("Distillery", "mug.fill")
        case .musicVenue:          return ("Live Music", "music.note")
        case .animalService:       return ("Vet", "pawprint.fill")
        case .automotiveRepair:    return ("Auto Repair", "wrench.and.screwdriver.fill")
        case .landmark:            return ("Landmark", "star.fill")
        case .nationalMonument:    return ("Monument", "building.columns.fill")
        case .castle, .fortress:   return ("Castle", "building.2.fill")
        case .conventionCenter:    return ("Convention Ctr", "building.2.fill")
        case .fairground:          return ("Fair", "sparkles")
        case .planetarium:         return ("Planetarium", "moon.stars.fill")
        case .mailbox:             return ("Mailbox", "envelope.fill")
        case .rvPark:              return ("RV Park", "car.fill")
        case .baseball:            return ("Baseball", "baseball.fill")
        case .basketball:          return ("Basketball", "basketball.fill")
        case .soccer:              return ("Soccer", "soccerball")
        case .tennis:              return ("Tennis", "sportscourt.fill")
        case .volleyball:          return ("Volleyball", "sportscourt.fill")
        case .golf, .miniGolf:     return ("Golf", "sportscourt.fill")
        case .bowling:             return ("Bowling", "sportscourt.fill")
        case .goKart:              return ("Go-Kart", "flag.checkered")
        case .hiking:              return ("Hiking", "figure.walk")
        case .rockClimbing:        return ("Climbing", "figure.walk")
        case .skiing:              return ("Skiing", "figure.walk")
        case .skating, .skatePark: return ("Skating", "figure.walk")
        case .surfing:             return ("Surfing", "water.waves")
        case .swimming:            return ("Swimming", "water.waves")
        case .kayaking:            return ("Kayaking", "water.waves")
        case .fishing:             return ("Fishing", "fish.fill")
        default: break
        }
    }

    // Base categories (iOS 13+). `.store` / `.restaurant` stay coarse — placeDisplay
    // refines those from the business name.
    switch c {
    case .restaurant:               return ("Restaurant", "fork.knife")
    case .cafe:                     return ("Café", "cup.and.saucer.fill")
    case .bakery:                   return ("Bakery", "birthday.cake.fill")
    case .brewery:                  return ("Brewery", "mug.fill")
    case .winery:                   return ("Winery", "wineglass.fill")
    case .nightlife:                return ("Bar", "wineglass.fill")
    case .foodMarket:               return ("Market", "cart.fill")
    case .store:                    return ("Shop", "bag.fill")
    case .fitnessCenter:            return ("Gym", "dumbbell.fill")
    case .park, .nationalPark:      return ("Park", "tree.fill")
    case .museum:                   return ("Museum", "building.columns.fill")
    case .theater:                  return ("Theater", "theatermasks.fill")
    case .movieTheater:             return ("Cinema", "theatermasks.fill")
    case .hotel:                    return ("Hotel", "bed.double.fill")
    case .pharmacy:                 return ("Pharmacy", "cross.case.fill")
    case .bank, .atm:               return ("Bank", "banknote.fill")
    case .library:                  return ("Library", "books.vertical.fill")
    case .laundry:                  return ("Laundry", "washer.fill")
    case .hospital:                 return ("Hospital", "cross.fill")
    case .school:                   return ("School", "graduationcap.fill")
    case .university:               return ("University", "graduationcap.fill")
    case .stadium:                  return ("Stadium", "sportscourt.fill")
    case .aquarium:                 return ("Aquarium", "fish.fill")
    case .zoo:                      return ("Zoo", "pawprint.fill")
    case .beach:                    return ("Beach", "beach.umbrella.fill")
    case .amusementPark:            return ("Fun", "sparkles")
    case .postOffice:               return ("Post Office", "envelope.fill")
    case .carRental:                return ("Car Rental", "car.fill")
    default:                        return ("Place", "mappin.circle.fill")
    }
}

/// Apple's `pointOfInterestCategory` is often nil for text-search hits (typing a
/// business name), which would leave every typed place a generic pin. When the
/// category tells us nothing, infer a type from keywords in the name.
func inferPlaceFromName(_ name: String) -> (label: String, symbol: String)? {
    let n = name.lowercased()
    func has(_ words: [String]) -> Bool { words.contains { n.contains($0) } }

    // Order matters — first match wins. Collision-prone tokens (bar/barber/bbq,
    // deli/delivery) are ordered so the more specific one is checked first.

    // Coffee / juice
    if has(["coffee", "café", "cafe", "espresso", "roaster", "coffeehouse"]) { return ("Café", "cup.and.saucer.fill") }
    if has(["juice", "smoothie", "açaí", "acai"]) { return ("Juice Bar", "cup.and.saucer.fill") }

    // Bakery / sweets (checked before "bar" — none contain it)
    if has(["bakery", "bagel", "patisserie", "boulangerie", "bread", "donut", "doughnut", "croissant"]) { return ("Bakery", "birthday.cake.fill") }
    if has(["ice cream", "gelato", "creamery", "frozen yogurt", "froyo", "dessert", "candy shop", "chocolate", "sweets"]) { return ("Sweets", "birthday.cake.fill") }

    // BBQ + barber BEFORE "bar" (both contain the substring "bar")
    if has(["bbq", "barbecue", "smokehouse", "smoke house"]) { return ("BBQ", "flame.fill") }
    if has(["barber", "barbershop"]) { return ("Barber", "scissors") }

    // Food — specific cuisines
    if has(["pizza", "pizzeria"]) { return ("Pizza", "fork.knife") }
    if has(["sushi", "omakase", "izakaya"]) { return ("Sushi", "fork.knife") }
    if has(["ramen", "noodle", "pho ", "udon", "soba"]) { return ("Noodles", "fork.knife") }
    if has(["taco", "taqueria", "burrito", "cantina", "mexican"]) { return ("Tacos", "fork.knife") }
    if has(["burger", "smashburger", "shake shack"]) { return ("Burgers", "fork.knife") }
    if has(["delicatessen", "sandwich", "hoagie", "sub shop", "bodega"]) { return ("Deli", "fork.knife") }

    // Bar / brewery / wine (after barber + bbq)
    if has(["brewery", "brewing", "taproom", "beer garden", "biergarten"]) { return ("Brewery", "mug.fill") }
    if has(["wine bar", "wine shop", "vintner", "enoteca", "winery"]) { return ("Wine", "wineglass.fill") }
    if has(["cocktail", "speakeasy", "pub", "tavern", "lounge", "saloon", "beer hall", "dive bar", "sports bar", " bar", "bar "]) { return ("Bar", "wineglass.fill") }

    // Fitness
    if has(["yoga", "pilates", "barre"]) { return ("Yoga", "figure.yoga") }
    if has(["gym", "fitness", "crossfit", "climbing", "spin studio", "cycle", "boxing", "martial",
            "vital", "equinox", "crunch", "blink", "soulcycle", "barry", "planet fitness",
            "orangetheory", "f45", "solidcore", "rumble", "chelsea piers", "dogpound"]) { return ("Gym", "dumbbell.fill") }

    // Beauty / personal care
    if has(["nail", "manicure", "pedicure"]) { return ("Nails", "sparkles") }
    if has(["massage", "day spa", "med spa", "sauna", "bathhouse", "wellness center"]) { return ("Spa", "sparkles") }
    if has(["salon", "hair", "blowout", "brow", "lash"]) { return ("Salon", "scissors") }
    if has(["tattoo", "piercing"]) { return ("Tattoo", "paintbrush.pointed.fill") }

    // Health
    if has(["pharmacy", "drug store", "chemist", " rx", "duane reade", "walgreens", "cvs"]) { return ("Pharmacy", "cross.case.fill") }
    if has(["dental", "dentist", "orthodont"]) { return ("Dentist", "cross.case.fill") }
    if has(["veterin", "animal hospital", "animal clinic", "vet clinic"]) { return ("Vet", "pawprint.fill") }
    if has(["urgent care", "medical center", "health center", "clinic", "hospital"]) { return ("Clinic", "cross.fill") }
    if has(["optic", "eyewear", "eyeglass", "vision center"]) { return ("Eyewear", "eyeglasses") }

    // Retail
    if has(["bookstore", "bookshop", "books", "library"]) { return ("Books", "books.vertical.fill") }
    if has(["florist", "flowers", "floral"]) { return ("Florist", "leaf.fill") }
    if has(["hardware", "lumber", "home depot", "ace hardware"]) { return ("Hardware", "hammer.fill") }
    if has(["boutique", "clothing", "apparel", "menswear", "womenswear", "vintage", "thrift"]) { return ("Clothing", "tshirt.fill") }
    if has(["shoe", "sneaker", "footwear"]) { return ("Shoes", "bag.fill") }
    if has(["jewel", "diamonds", "goldsmith"]) { return ("Jewelry", "sparkles") }
    if has(["electronics", "computer", "phone repair", "apple store", "best buy"]) { return ("Electronics", "iphone") }
    if has(["record", "vinyl", "music store", "instruments", "guitar"]) { return ("Music", "music.note") }
    if has(["pet shop", "pet store", "petco", "petsmart", "pet supply"]) { return ("Pet Shop", "pawprint.fill") }
    if has(["grocery", "grocer", "supermarket", "greenmarket", "farmers market", "market"]) { return ("Market", "cart.fill") }

    // Services / civic
    if has(["laundry", "laundromat", "cleaners", "dry clean", "wash & fold"]) { return ("Laundry", "washer.fill") }
    if has(["bank", "atm", "credit union", "chase", "citibank"]) { return ("Bank", "banknote.fill") }
    if has(["hotel", "inn", "suites", "hostel", "motel"]) { return ("Hotel", "bed.double.fill") }
    if has(["museum", "gallery", "exhibit"]) { return ("Museum", "building.columns.fill") }
    if has(["theater", "theatre", "cinema", "playhouse"]) { return ("Theater", "theatermasks.fill") }
    if has(["park", "garden", "playground", "greenway"]) { return ("Park", "tree.fill") }
    if has(["church", "cathedral", "temple", "synagogue", "mosque"]) { return ("Worship", "building.columns.fill") }

    // Generic sit-down food (last, so specifics above win)
    if has(["restaurant", "kitchen", "grill", "thai", "diner", "bistro", "trattoria", "osteria",
            "steakhouse", "eatery", "brasserie", "ristorante"]) { return ("Restaurant", "fork.knife") }

    return nil
}

/// Resolve a place's label + symbol. Apple's category is coarse — it buckets most
/// places as a generic Shop (.store), Restaurant (.restaurant), or Place (nil). For
/// those, refine from the business name first (a bookstore → Books, a pizzeria →
/// Pizza), which is what makes the tags granular instead of "Shop, Shop, Shop".
/// A specific Apple category (Café, Gym, Bakery…) is trusted as-is.
func placeDisplay(name: String, category: MKPointOfInterestCategory?) -> (label: String, symbol: String) {
    let byCategory = placeCategoryDisplay(category)
    // The generic buckets Apple over-uses — refine these from the name when we can.
    let genericSymbols: Set<String> = ["mappin.circle.fill", "bag.fill", "fork.knife"]
    if genericSymbols.contains(byCategory.symbol), let refined = inferPlaceFromName(name) {
        return refined
    }
    return byCategory
}

// MARK: - Place Picker (Apple Maps POI search)

struct PlacePickerSheet: View {
    let center: CLLocationCoordinate2D
    var selected: TaggedPlace?
    var onPick: (TaggedPlace?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [TaggedPlace] = []
    @State private var loading = false

    // Show every real storefront, only dropping transit/parking/infrastructure.
    // A whitelist silently hid businesses Apple filed under an odd category
    // (e.g. a climbing gym that isn't tagged .fitnessCenter).
    private let excludedCategories: [MKPointOfInterestCategory] = [
        .publicTransport, .parking, .gasStation, .evCharger,
        .airport, .campground, .marina,
    ]

    // Precision comes from closest-first + the cap, not a razor-thin radius —
    // ~360 ft is forgiving enough not to drop the business you're standing near
    // (long blocks / GPS drift), while the cap keeps a dense block manageable.
    private let maxPlaceMeters: CLLocationDistance = 110
    private let maxResults = 12

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                Text("Only places at your pin · closest first")
                    .font(BTFont.mono(size: 10)).foregroundStyle(Color.btText3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BTSpacing.lg).padding(.bottom, BTSpacing.sm)
                Divider().background(Color.btLine)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        noPlaceRow
                        Divider().background(Color.btLine).padding(.leading, BTSpacing.lg)

                        if loading && results.isEmpty {
                            ProgressView().tint(Color.btText3)
                                .frame(maxWidth: .infinity).padding(.top, BTSpacing.xxxl)
                        } else if results.isEmpty {
                            Text(query.isEmpty
                                 ? "No businesses right at your pin."
                                 : "\u{201C}\(query)\u{201D} isn\u{2019}t at your pin — only places here can be tagged.")
                                .font(BTFont.body(size: 13)).foregroundStyle(Color.btText3)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity).padding(.horizontal, BTSpacing.xl).padding(.top, BTSpacing.xxxl)
                        } else {
                            ForEach(results) { place in
                                placeRow(place)
                                Divider().background(Color.btLine).padding(.leading, 68)
                            }
                        }
                    }
                }
            }
            .background(Color.btBg)
            .navigationTitle("Tag a place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.btText2)
                }
            }
        }
        .task(id: query) {
            let q = query.trimmingCharacters(in: .whitespaces)
            if q.isEmpty {
                await runNearby()
            } else {
                try? await Task.sleep(for: .milliseconds(300))
                if Task.isCancelled { return }
                await runSearch(q)
            }
        }
    }

    private var searchField: some View {
        BTSearchField(text: $query, placeholder: "Search a place near you", autocapitalization: .words)
            .padding(BTSpacing.lg)
    }

    private var noPlaceRow: some View {
        Button {
            onPick(nil); dismiss()
        } label: {
            HStack(spacing: BTSpacing.md) {
                // A plain corner comment is lime (Route 2), same as its pin.
                Image(systemName: "mappin")
                    .font(.system(size: 15)).foregroundStyle(Color.btLime)
                    .frame(width: 40, height: 40)
                    .background(Color.btLime.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.btLime.opacity(0.22), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                Text("No business, just the pin")
                    .font(BTFont.bodySemibold(size: 14)).foregroundStyle(Color.btText)
                Spacer(minLength: 0)
                if selected == nil {
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.btLime)
                }
            }
            .padding(.vertical, 8).padding(.horizontal, BTSpacing.lg)
        }
        .buttonStyle(.plain)
    }

    private func placeRow(_ place: TaggedPlace) -> some View {
        Button {
            onPick(place); dismiss()
        } label: {
            HStack(spacing: BTSpacing.md) {
                // A tagged business is house-blue (Route 2), same as its pin.
                Image(systemName: place.symbol)
                    .font(.system(size: 16)).foregroundStyle(Color.btHouse)
                    .frame(width: 40, height: 40)
                    .background(Color.btHouse.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.btHouse.opacity(0.28), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(BTFont.bodySemibold(size: 15)).foregroundStyle(Color.btText).lineLimit(1)
                    Text("\(place.category) · \(distanceString(place))")
                        .font(BTFont.mono(size: 11)).foregroundStyle(Color.btText3)
                }
                Spacer(minLength: 0)
                Image(systemName: selected?.name == place.name ? "checkmark" : "plus")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.btHouse)
            }
            .padding(.vertical, 8).padding(.horizontal, BTSpacing.lg)
        }
        .buttonStyle(.plain)
    }

    private func distanceString(_ place: TaggedPlace) -> String {
        let meters = CLLocation(latitude: center.latitude, longitude: center.longitude)
            .distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
        let feet = meters * 3.28084
        if feet < 1000 { return "\(Int((feet / 10).rounded()) * 10) ft" }
        return String(format: "%.1f mi", meters / 1609.34)
    }

    private func mapItemToPlace(_ item: MKMapItem, nearby: [MKMapItem] = []) -> TaggedPlace? {
        guard let name = item.name else { return nil }
        var (label, symbol) = placeDisplay(name: name, category: item.pointOfInterestCategory)

        // Icon rescue: a typed hit often has no Apple category, so if it's still
        // a generic pin, borrow the category from a nearby POI at the same spot
        // (the nearby request carries reliable categories). This is what makes
        // the right icon show up across the board, not just for known brands.
        if symbol == "mappin.circle.fill" {
            let here = item.placemark.coordinate
            if let match = nearby.first(where: { poi in
                poi.pointOfInterestCategory != nil &&
                CLLocation(latitude: here.latitude, longitude: here.longitude)
                    .distance(from: CLLocation(latitude: poi.placemark.coordinate.latitude,
                                               longitude: poi.placemark.coordinate.longitude)) < 25
            }) {
                (label, symbol) = placeCategoryDisplay(match.pointOfInterestCategory)
            }
        }

        let c = item.placemark.coordinate
        return TaggedPlace(name: name, category: label, symbol: symbol,
                           latitude: c.latitude, longitude: c.longitude)
    }

    private func mapItems(_ request: MKLocalSearch.Request) async -> [MKMapItem] {
        (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
    }

    private func mapItems(_ request: MKLocalPointsOfInterestRequest) async -> [MKMapItem] {
        (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
    }

    private func meters(to place: TaggedPlace) -> CLLocationDistance {
        CLLocation(latitude: center.latitude, longitude: center.longitude)
            .distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
    }

    /// Keep only places actually at the pin, closest first, capped so a dense
    /// block shows the nearest handful rather than everything in range.
    private func withinRange(_ places: [TaggedPlace]) -> [TaggedPlace] {
        Array(places
            .filter { meters(to: $0) <= maxPlaceMeters }
            .sorted { meters(to: $0) < meters(to: $1) }
            .prefix(maxResults))
    }

    private func runNearby() async {
        loading = true
        // Apple only returns POIs inside this radius, so the request itself
        // enforces the cap; we still sort closest-first.
        let req = MKLocalPointsOfInterestRequest(center: center, radius: maxPlaceMeters)
        req.pointOfInterestFilter = MKPointOfInterestFilter(excluding: excludedCategories)
        let nearby = await mapItems(req)
        results = withinRange(nearby.compactMap { mapItemToPlace($0, nearby: nearby) })
        loading = false
    }

    private func runSearch(_ q: String) async {
        loading = true
        // A text query's region is only a bias, not a hard limit — Apple can
        // return matches far away. Search a tight box AND filter by real
        // distance so you can't tag a business that isn't at your pin.
        let textReq = MKLocalSearch.Request()
        textReq.naturalLanguageQuery = q
        textReq.region = MKCoordinateRegion(center: center,
                                            latitudinalMeters: maxPlaceMeters * 2,
                                            longitudinalMeters: maxPlaceMeters * 2)
        // Fetch nearby POIs in parallel so typed hits can borrow real categories.
        let poiReq = MKLocalPointsOfInterestRequest(center: center, radius: maxPlaceMeters)
        poiReq.pointOfInterestFilter = MKPointOfInterestFilter(excluding: excludedCategories)

        async let textItems = mapItems(textReq)
        async let nearbyItems = mapItems(poiReq)
        let (text, nearby) = await (textItems, nearbyItems)
        results = withinRange(text.compactMap { mapItemToPlace($0, nearby: nearby) })
        loading = false
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ComposeView()
        .environment(AppState())
        .environment(LocationService())
        .preferredColorScheme(.dark)
}
