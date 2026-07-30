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
    // Optional business the street comment is tagged to (Apple Maps POI).
    @State private var taggedPlace: TaggedPlace?
    @State private var showPlacePicker = false
    @FocusState private var textFocused: Bool

    /// Pin can be toggled off locally (the ≡ footer button) without closing
    private var effectivePin: CLLocationCoordinate2D? { pinCleared ? nil : pinDropLocation }
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
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
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
                    footerIcon("line.3.horizontal") { pinCleared = true }
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
            let queued = Post(
                id: UUID(), userId: userId, neighborhoodId: neighborhoodId,
                text: body, isDailyPrompt: false, score: 0, replyCount: 0,
                reportCount: 0, status: .live, createdAt: Date()
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
                    let pin = try await pinService.createPin(
                        userId: userId,
                        coordinate: pinLocation,
                        cornerName: pinCornerName ?? resolvedStreet,
                        neighborhoodId: neighborhoodId,
                        placeName: taggedPlace?.name,
                        placeCategory: taggedPlace?.category,
                        placeSymbol: taggedPlace?.symbol
                    )
                    if let post = await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId, author: author, pinId: pin.id) {
                        // Surface your just-placed post + its pin immediately, WITH
                        // the corner — the DB feed reload doesn't carry the pin's
                        // corner yet (see handoff: embed pin in the post payload).
                        localContent.add(post: post, pin: pin)
                        routeAfterPost()
                    }
                } catch {
                    print("Failed to create pin: \(error)")
                }
            } else {
                if let post = await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId, author: author) {
                    localContent.add(post: post)
                    routeAfterPost()
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

/// Apple POI category → friendly label + SF Symbol.
func placeCategoryDisplay(_ c: MKPointOfInterestCategory?) -> (label: String, symbol: String) {
    switch c {
    case .some(.restaurant):            return ("Restaurant", "fork.knife")
    case .some(.cafe):                  return ("Café", "cup.and.saucer.fill")
    case .some(.bakery):                return ("Bakery", "birthday.cake.fill")
    case .some(.brewery), .some(.winery): return ("Brewery", "mug.fill")
    case .some(.nightlife):             return ("Bar", "wineglass.fill")
    case .some(.foodMarket):            return ("Market", "cart.fill")
    case .some(.store):                 return ("Shop", "bag.fill")
    case .some(.fitnessCenter):         return ("Gym", "dumbbell.fill")
    case .some(.park), .some(.nationalPark): return ("Park", "tree.fill")
    case .some(.museum):                return ("Museum", "building.columns.fill")
    case .some(.theater), .some(.movieTheater): return ("Theater", "theatermasks.fill")
    case .some(.hotel):                 return ("Hotel", "bed.double.fill")
    case .some(.pharmacy):              return ("Pharmacy", "cross.case.fill")
    case .some(.bank), .some(.atm):     return ("Bank", "banknote.fill")
    case .some(.library):               return ("Library", "books.vertical.fill")
    case .some(.laundry):               return ("Laundry", "washer.fill")
    default:                            return ("Place", "mappin.circle.fill")
    }
}

/// Apple's `pointOfInterestCategory` is often nil for text-search hits (typing a
/// business name), which would leave every typed place a generic pin. When the
/// category tells us nothing, infer a type from keywords in the name.
func inferPlaceFromName(_ name: String) -> (label: String, symbol: String)? {
    let n = name.lowercased()
    func has(_ words: [String]) -> Bool { words.contains { n.contains($0) } }

    if has(["gym", "fitness", "crossfit", "pilates", "yoga", "climbing", "barre",
            "spin studio", "cycle", "boxing", "martial",
            // common gym brands that carry no category hint in their name
            "vital", "equinox", "crunch", "blink", "soulcycle", "barry",
            "planet fitness", "orangetheory", "f45", "solidcore", "rumble",
            "chelsea piers", "dogpound"]) { return ("Gym", "dumbbell.fill") }
    if has(["coffee", "café", "cafe", "espresso", "roaster"]) { return ("Café", "cup.and.saucer.fill") }
    if has(["pizza", "pizzeria"]) { return ("Restaurant", "fork.knife") }
    if has(["bakery", "bagel", "patisserie", "bread", "donut", "doughnut"]) { return ("Bakery", "birthday.cake.fill") }
    if has(["restaurant", "kitchen", "grill", "taco", "taqueria", "sushi", "ramen",
            "thai", "noodle", "diner", "bistro", "trattoria", "deli"]) { return ("Restaurant", "fork.knife") }
    if has(["bar", "pub", "tavern", "lounge", "cocktail"]) { return ("Bar", "wineglass.fill") }
    if has(["brewery", "beer", "taproom"]) { return ("Brewery", "mug.fill") }
    if has(["wine", "winery", "vintner"]) { return ("Wine", "wineglass.fill") }
    if has(["pharmacy", "drug", "chemist", "rx"]) { return ("Pharmacy", "cross.case.fill") }
    if has(["laundry", "laundromat", "cleaners", "dry clean"]) { return ("Laundry", "washer.fill") }
    if has(["barber", "salon", "nails", "spa", "beauty", "hair"]) { return ("Salon", "scissors") }
    if has(["hotel", "inn", "suites", "hostel"]) { return ("Hotel", "bed.double.fill") }
    if has(["bank", "atm", "credit union"]) { return ("Bank", "banknote.fill") }
    if has(["market", "grocery", "bodega", "mart", "grocer"]) { return ("Market", "cart.fill") }
    if has(["books", "bookstore", "library"]) { return ("Books", "books.vertical.fill") }
    if has(["museum", "gallery"]) { return ("Museum", "building.columns.fill") }
    if has(["theater", "theatre", "cinema"]) { return ("Theater", "theatermasks.fill") }
    if has(["park", "garden"]) { return ("Park", "tree.fill") }
    return nil
}

/// Resolve a place's label + symbol: trust Apple's category when it's specific,
/// otherwise fall back to name keywords, otherwise a generic pin.
func placeDisplay(name: String, category: MKPointOfInterestCategory?) -> (label: String, symbol: String) {
    let byCategory = placeCategoryDisplay(category)
    if byCategory.symbol != "mappin.circle.fill" { return byCategory }   // Apple was specific
    return inferPlaceFromName(name) ?? byCategory
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
        HStack(spacing: BTSpacing.sm) {
            Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(Color.btText3)
            TextField("Search a business or place", text: $query)
                .font(BTFont.body(size: 15)).foregroundStyle(Color.btText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(Color.btText3)
                }
            }
        }
        .padding(.horizontal, BTSpacing.md).padding(.vertical, 11)
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
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
