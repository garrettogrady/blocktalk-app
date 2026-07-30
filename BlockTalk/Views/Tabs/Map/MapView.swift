import MapKit
import SwiftUI

/// Identifiable wrapper so the pin-detail sheet is item-driven (presents only
/// once the post is resolved, never blank).
struct PinDetailItem: Identifiable {
    let pin: Pin
    let post: Post
    var id: UUID { pin.id }
}

struct MapTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @Environment(LocalContentStore.self) private var localContent
    @Environment(NeighborhoodCache.self) private var neighborhoodCache
    @State private var viewModel = MapViewModel()
    @State private var showComposeForPin = false
    @State private var polygons: [NeighborhoodPolygon] = []
    /// The neighborhood the user tapped — highlighted + named in a bottom card,
    /// pending confirmation. Tap-to-select-then-confirm (not instant navigate).
    @State private var selectedNeighborhood: String?
    // Item-driven so the sheet only presents once the post is resolved — avoids
    // the blank-first-tap sheet that `.sheet(isPresented:)` + separate state hits.
    @State private var selectedPinDetail: PinDetailItem?
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 40.7193, longitude: -73.9911)
    // The geographic coordinate directly under the drop reticle. Range-checking
    // and pin placement both use THIS (not region.center) so what you aim is
    // exactly what's checked and where the pin lands.
    @State private var mapSize: CGSize = .zero
    @State private var reticleCoord: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7193, longitude: -73.9911),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.024)
        )
    )
    @State private var showPreFrame = false

    // Known LES corners for the 200m drop-mode snap
    private let knownCorners: [(name: String, coord: CLLocationCoordinate2D)] = [
        ("Stanton & Norfolk", CLLocationCoordinate2D(latitude: 40.7211, longitude: -73.9871)),
        ("Essex & Rivington", CLLocationCoordinate2D(latitude: 40.7196, longitude: -73.9878)),
        ("Houston & Ludlow", CLLocationCoordinate2D(latitude: 40.7222, longitude: -73.9877)),
        ("Delancey & Allen", CLLocationCoordinate2D(latitude: 40.7186, longitude: -73.9898)),
        ("Clinton & Delancey", CLLocationCoordinate2D(latitude: 40.7181, longitude: -73.9862)),
    ]

    var body: some View {
        ZStack {
            MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: .all) {
                // Neighborhood polygon overlays
                ForEach(polygons) { polygon in
                    let isCurrent = isCurrentNeighborhood(polygon.name)
                    let isSelected = selectedNeighborhood == polygon.name
                    ForEach(Array(polygon.rings.enumerated()), id: \.offset) { _, ring in
                        MapPolygon(coordinates: ring)
                            .stroke(
                                isSelected || isCurrent ? Color.btLime : Color.white.opacity(0.58),
                                lineWidth: isSelected ? 2.5 : (isCurrent ? 1.5 : 1.7)
                            )
                            .foregroundStyle(
                                isSelected
                                    ? Color.btLime.opacity(0.22)
                                    : isCurrent
                                        ? Color.btLime.opacity(0.07)
                                        : Color.white.opacity(0.02)
                            )
                    }
                }

                // Neighborhood names come from the base map only — we no longer
                // draw our own lime label over the highlighted one (it showed
                // inconsistently vs the base-map labels). The highlighted polygon
                // is still marked by its lime outline/fill, and the bottom card
                // names the tapped neighborhood.

                // Pin annotations (bundled samples + anything created this session)
                ForEach(viewModel.pins + localContent.pins) { pin in
                    Annotation("", coordinate: pin.coordinate) {
                        // Route 2: business-tagged pins are house-blue with their
                        // category glyph; plain corners stay lime dots.
                        PulsatingPinView(
                            tint: pin.placeName != nil ? Color.btHouse : Color.btLime,
                            symbol: pin.placeName != nil ? (pin.placeSymbol ?? "mappin.circle.fill") : nil
                        )
                        .onTapGesture {
                            openPinDetail(pin)
                        }
                    }
                }

                // House-blue "you are here" dot — only once location is granted
                if let loc = locationService.currentLocation {
                    Annotation("", coordinate: loc) {
                        HouseBlueDot()
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)
            // Lift Apple's required logo/Legal up so the tab bar + bottom bars
            // don't clip it (App Store compliance).
            .mapControls { }
            .contentMargins(.bottom, 96, for: .automatic)
            .onMapCameraChange { context in
                // Only churn state while dropping a pin. Doing this on every
                // camera frame while just browsing re-rendered every annotation
                // continuously, which made the pins visibly jitter/drift.
                guard viewModel.isDropMode else { return }
                viewModel.updateRadius(from: context.region)
                mapCenter = context.region.center
                // Resolve the coordinate under the reticle in the SAME space the
                // reticle is drawn, so aim == checked == dropped.
                if mapSize != .zero {
                    reticleCoord = proxy.convert(reticlePoint, from: .local)
                }
            }
            // Resolve the reticle the instant drop mode starts, since the camera
            // handler above now only runs while dropping.
            .onChange(of: viewModel.isDropMode) { _, dropping in
                if dropping, mapSize != .zero {
                    reticleCoord = proxy.convert(reticlePoint, from: .local)
                }
            }
            // Tap to select; tap the selected one again to open its feed; tap
            // empty water/far away to deselect. Skips taps on a pin.
            .onTapGesture { screenPoint in
                guard !viewModel.isDropMode,
                      let coord = proxy.convert(screenPoint, from: .local),
                      !isNearPin(coord) else { return }
                handleTap(at: coord)
            }
            // Reticle lives in the MapReader's `.local` space (same as proxy),
            // pinned to the exact point we range-check.
            .overlay {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { mapSize = geo.size }
                        .onChange(of: geo.size) { _, newValue in mapSize = newValue }
                    if viewModel.isDropMode {
                        PinDropOverlay().position(reticlePoint)
                    }
                }
            }
            }
            .ignoresSafeArea() // on the MapReader so its `.local` space == tap space
            // MapReader

            // Top pills
            VStack {
                if viewModel.isDropMode {
                    dropModePill
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.top, BTSpacing.sm)
                } else {
                    VStack(spacing: BTSpacing.sm) {
                        // Top pill — "You're in X" only makes sense once we
                        // actually know where you are (location granted). Off →
                        // a logical "location off" note instead of a false home.
                        HStack(spacing: BTSpacing.xs) {
                            if locationService.permissionState == .granted {
                                Circle().fill(Color.btLime).frame(width: 6, height: 6)
                                Text("You're in \(hereShortCode)")
                                    .font(BTFont.bodySemibold(size: 12))
                                    .foregroundStyle(Color.btText)
                            } else {
                                Image(systemName: "location.slash.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.btWarn)
                                Text("Location off · viewing only")
                                    .font(BTFont.bodySemibold(size: 12))
                                    .foregroundStyle(Color.btText)
                            }
                        }
                        .padding(.horizontal, BTSpacing.md)
                        .padding(.vertical, BTSpacing.sm)
                        .background(Color.btSurface.opacity(0.95))
                        .clipShape(Capsule())

                        // Contextual hint — only while nothing's selected. The
                        // moment you tap a neighborhood, the bottom card takes over
                        // and this gets out of the way.
                        if selectedNeighborhood == nil {
                            Text("Tap a neighborhood to view its feed")
                                .font(BTFont.body(size: 11))
                                .foregroundStyle(Color.btText2)
                                .padding(.horizontal, BTSpacing.md)
                                .padding(.vertical, BTSpacing.xs)
                                .background(Color.btSurface.opacity(0.9))
                                .clipShape(Capsule())
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, BTSpacing.sm)
                }

                Spacer()
            }

            // Drop mode overlay (the reticle itself is drawn inside the MapReader
            // so it shares the map's coordinate space — see .overlay above).
            if viewModel.isDropMode {
                VStack {
                    Spacer()
                    HStack(spacing: BTSpacing.lg) {
                        Button {
                            viewModel.cancelDrop()
                        } label: {
                            Text("Cancel")
                                .font(BTFont.bodySemibold(size: 15))
                                .foregroundStyle(Color.btText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BTSpacing.md)
                                .background(Color.btSurface)
                                .cornerRadius(BTRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BTRadius.md)
                                        .stroke(Color.btLine, lineWidth: 1)
                                )
                        }

                        Button {
                            // Capture the drop location (mapCenter = the reticle),
                            // then leave drop mode so we don't return to it after
                            // posting — that stranded the user in the drop overlay.
                            guard dropInRange else { return }
                            showComposeForPin = true
                            viewModel.cancelDrop()
                        } label: {
                            Text(dropInRange ? "Drop pin here" : "Out of range")
                                .font(BTFont.bodySemibold(size: 15))
                                .foregroundStyle(dropInRange ? Color.btBg : Color.btText3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BTSpacing.md)
                                .background(dropInRange ? Color.btLime : Color.btSurface2)
                                .cornerRadius(BTRadius.md)
                        }
                        .disabled(!dropInRange)
                    }
                    .padding(.horizontal, BTSpacing.xxl)
                    .padding(.bottom, BTSpacing.xxxl)
                }
            }

            // Selection card, FAB, or location gate
            if !viewModel.isDropMode {
                VStack {
                    Spacer()

                    if let selected = selectedNeighborhood {
                        selectionCard(selected)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.bottom, BTSpacing.xxxl)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if locationService.permissionState == .granted {
                        Button {
                            // Start the drop reticle on your current location — the
                            // most useful starting point, and it keeps the pin
                            // in-range even if you'd panned off to browse elsewhere.
                            selectedNeighborhood = nil
                            if let here = locationService.currentLocation {
                                centerReticle(on: here)
                            } else {
                                focus(on: activeNeighborhoodName)
                            }
                            viewModel.enterDropMode()
                        } label: {
                            HStack(spacing: BTSpacing.sm) {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Drop a thought")
                                    .font(BTFont.bodySemibold(size: 14))
                            }
                            .foregroundStyle(Color.btOnAccent)
                            .padding(.horizontal, BTSpacing.xl)
                            .padding(.vertical, BTSpacing.md)
                            .background(Color.btLime)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.bottom, BTSpacing.xxxl)
                    } else {
                        // Location gate — same centered-capsule shape + position as
                        // the "Drop a thought" FAB above, so the two map states are
                        // consistent instead of a floating full-width pill.
                        Button {
                            locationGateTap(locationService, showPreFrame: $showPreFrame)
                        } label: {
                            HStack(spacing: BTSpacing.sm) {
                                Image(systemName: "location.slash.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text(locationService.permissionState == .denied
                                     ? "Open Settings · location off"
                                     : "Enable location to post")
                                    .font(BTFont.bodySemibold(size: 14))
                            }
                            .foregroundStyle(Color.btOnAccent)
                            .padding(.horizontal, BTSpacing.xl)
                            .padding(.vertical, BTSpacing.md)
                            .background(Color.btWarn)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.bottom, BTSpacing.xxxl)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showComposeForPin) {
            ComposeView(
                postingNeighborhood: appState.physicalNeighborhood ?? locationService.currentNeighborhood,
                pinDropLocation: dropCoordinate,
                pinCornerName: snappedCorner(dropCoordinate)
            )
        }
        .sheet(isPresented: $showPreFrame) {
            LocationPreFrameSheet()
        }
        .sheet(item: $selectedPinDetail) { detail in
            NavigationStack {
                // Pin detail draws the corner map + business (house-blue) / corner
                // (lime) color straight from the pin — the corner context a plain
                // PostDetailView drops. PinDetailView owns its title + share.
                PinDetailView(pin: detail.pin, post: detail.post)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                selectedPinDetail = nil
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.btText2)
                            }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        // Fires when the flag flips while the Map tab is already alive.
        .onChange(of: appState.pendingPinPlacement) { _, pending in
            if pending { enterDropFromCompose() }
        }
        .task {
            polygons = NeighborhoodPolygonLoader.load()
            // Also handle the case where the Map tab is being created for the
            // first time by this very hand-off — onChange never saw the flip,
            // so honor the pending request as soon as the polygons are ready.
            if appState.pendingPinPlacement { enterDropFromCompose() }
            await viewModel.loadNeighborhoods()
            await viewModel.loadAllPins()
        }
    }

    /// Enter drop mode in response to the compose → "drop a pin" hand-off.
    private func enterDropFromCompose() {
        selectedNeighborhood = nil
        if let here = locationService.currentLocation {
            centerReticle(on: here)
        } else {
            focus(on: activeNeighborhoodName)
        }
        viewModel.enterDropMode()
        appState.pendingPinPlacement = false
    }

    // MARK: - Helpers

    /// The single active neighborhood (only this one is highlighted). Uses the
    /// viewing neighborhood (reliable locally), falling back to GPS-resolved,
    /// then LES — never highlights two at once.
    /// The neighborhood you're physically in — the postable zone (green outline +
    /// "You're in X"). NOT the one you're browsing: you can drop pins only here.
    private var activeNeighborhoodName: String {
        appState.physicalNeighborhood?.name ?? locationService.currentNeighborhood?.name ?? "Lower East Side"
    }

    private var hereShortCode: String {
        appState.physicalNeighborhood?.shortCode ?? locationService.currentNeighborhood?.shortCode ?? "NYC"
    }

    private func isCurrentNeighborhood(_ polygonName: String) -> Bool {
        polygonName.lowercased() == activeNeighborhoodName.lowercased()
    }

    /// Exact geofence: in-range iff the reticle is inside the SAME polygon(s)
    /// drawn green (the highlighted neighborhood). WYSIWYG — inside the green
    /// outline you can post, outside you can't. If nothing is highlighted we
    /// don't block. Precision is only as good as the bundled polygon shape
    /// (see HANDOFF — swap in the exact NTA polygons to tighten the outline).
    /// Screen point of the reticle ring, in the MapReader's `.local` space.
    /// This is the single source of truth for "where the pin goes".
    private var reticlePoint: CGPoint {
        CGPoint(x: mapSize.width / 2, y: mapSize.height * 0.42)
    }

    /// The coordinate the pin will drop at — under the reticle (falls back to the
    /// region center only before the reticle coordinate has resolved).
    private var dropCoordinate: CLLocationCoordinate2D { reticleCoord ?? mapCenter }

    private var dropInRange: Bool {
        let highlighted = polygons.filter { isCurrentNeighborhood($0.name) }
        guard !highlighted.isEmpty else { return true }
        return highlighted.contains { $0.contains(dropCoordinate) }
    }

    private func snappedCorner(_ coord: CLLocationCoordinate2D) -> String? {
        let here = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        for c in knownCorners {
            let there = CLLocation(latitude: c.coord.latitude, longitude: c.coord.longitude)
            if here.distance(from: there) <= 200 { return c.name }
        }
        return nil
    }

    private var dropModePill: some View {
        let corner = snappedCorner(dropCoordinate)
        let inRange = dropInRange
        return VStack(spacing: 3) {
            Text(inRange ? "📍 SELECT A LOCATION" : "📍 OUT OF RANGE")
                .font(BTFont.monoBold(size: 11.5))
                .tracking(0.8)
                .foregroundStyle(inRange ? Color.btText : Color.btWarn)
            Text(inRange
                 ? (corner ?? "drag the map to position the pin")
                 : "you can only drop pins in your current neighborhood")
                .font(inRange && corner != nil ? BTFont.monoBold(size: 11) : BTFont.body(size: 11))
                .foregroundStyle(inRange && corner != nil ? Color.btLime : (inRange ? Color.btText2 : Color.btWarn.opacity(0.85)))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.sm)
        // Solid dark pill so it stays legible over the map; the orange text +
        // border carry the out-of-range warning.
        .background(Color.btSurface.opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.lg)
                .stroke(inRange ? Color.btLine : Color.btWarn, lineWidth: inRange ? 1 : 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    /// Bottom card shown after tapping a neighborhood: names it + confirms.
    private func selectionCard(_ name: String) -> some View {
        let boro = NeighborhoodDirectory.all.first { $0.name == name }?.borough
        return VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(BTFont.display(size: 18))
                        .foregroundStyle(Color.btText)
                    HStack(spacing: 5) {
                        if let boro {
                            Text(boro.uppercased())
                                .font(BTFont.monoBold(size: 9))
                                .tracking(1.2)
                                .foregroundStyle(Color.btText3)
                            Text("·").foregroundStyle(Color.btText3)
                        }
                        Circle().fill(Color.btLime).frame(width: 5, height: 5)
                        Text("\(viewModel.talkingCounts[name] ?? 0) talking")
                            .font(BTFont.monoBold(size: 9))
                            .tracking(0.8)
                            .foregroundStyle(Color.btLime)
                    }
                }
                Spacer()
                Button { withAnimation { selectedNeighborhood = nil } } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.btText3)
                        .frame(width: 28, height: 28)
                        .background(Color.btSurface2)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            Button { openFeed(name) } label: {
                HStack(spacing: 6) {
                    Text("View \(name) feed")
                        .font(BTFont.bodySemibold(size: 14))
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.btOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BTSpacing.md)
                .background(Color.btLime)
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(BTSpacing.lg)
        .background(Color.btSurface.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btLime.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
    }

    private func openPinDetail(_ pin: Pin) {
        // Session-created street comment first, else the bundled sample post.
        if let post = localContent.post(forPinId: pin.id) {
            selectedPinDetail = PinDetailItem(pin: pin, post: post)
            return
        }
        Task {
            do {
                let postService = PostService()
                if let post = try await postService.fetchPostForPin(pin.id) {
                    selectedPinDetail = PinDetailItem(pin: pin, post: post)
                }
            } catch {
                print("Failed to load post for pin: \(error)")
            }
        }
    }

    /// Tap routing: inside a neighborhood selects it (or opens it if it's
    /// already selected — double-tap-to-confirm); a near-miss snaps to the
    /// closest neighborhood (forgives edge imprecision); a far tap (water,
    /// empty space) clears the selection.
    private func handleTap(at coord: CLLocationCoordinate2D) {
        if let hit = polygons.first(where: { $0.contains(coord) }) {
            if hit.name == selectedNeighborhood {
                openFeed(hit.name)          // second tap on the selected → open
            } else {
                select(hit.name)
            }
            return
        }
        if let near = nearestPolygon(to: coord), near.dist < 250 {
            select(near.name)               // just outside an edge → snap in
        } else if selectedNeighborhood != nil {
            withAnimation(.easeOut(duration: 0.2)) { selectedNeighborhood = nil }
        }
    }

    private func select(_ name: String) {
        withAnimation(.easeOut(duration: 0.18)) { selectedNeighborhood = name }
        focus(on: name)                     // zoom-to-fit the neighborhood
        Task { await viewModel.loadTalkingCount(name: name) }
    }

    /// Nearest neighborhood to a coordinate by distance to its outline.
    private func nearestPolygon(to coord: CLLocationCoordinate2D) -> (name: String, dist: CLLocationDistance)? {
        var best: (String, CLLocationDistance)?
        for poly in polygons {
            for ring in poly.rings where ring.count > 2 {
                for p in ring {
                    let d = distance(coord, p)
                    if best == nil || d < best!.1 { best = (poly.name, d) }
                }
            }
        }
        return best.map { (name: $0.0, dist: $0.1) }
    }

    /// Gently pan/zoom so the whole selected neighborhood is in view.
    private func focus(on name: String) {
        guard let poly = polygons.first(where: { $0.name == name }) else { return }
        var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0
        for ring in poly.rings {
            for p in ring {
                minLat = min(minLat, p.latitude);  maxLat = max(maxLat, p.latitude)
                minLng = min(minLng, p.longitude); maxLng = max(maxLng, p.longitude)
            }
        }
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.012),
                longitudeDelta: max((maxLng - minLng) * 1.5, 0.010)
            )
        )
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(region)
        }
    }

    /// Center the drop reticle on a coordinate. The reticle sits at 42% screen
    /// height (see reticlePoint), so bias the region center south by that fraction
    /// of the span — the coordinate lands right under the ring when drop mode opens.
    private func centerReticle(on coord: CLLocationCoordinate2D) {
        let latDelta = 0.006
        let lngDelta = 0.005
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coord.latitude - latDelta * 0.08,
                                           longitude: coord.longitude),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(region)
        }
    }

    /// True if the tap landed on a map pin (let the pin's own tap handle it).
    private func isNearPin(_ coord: CLLocationCoordinate2D) -> Bool {
        let here = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return viewModel.pins.contains {
            here.distance(from: CLLocation(latitude: $0.coordinate.latitude,
                                           longitude: $0.coordinate.longitude)) < 50
        }
    }

    private func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    /// Open the confirmed neighborhood's feed. Uses cached Supabase neighborhoods
    /// so the ID matches posts in the database.
    private func openFeed(_ name: String) {
        if let cached = neighborhoodCache.neighborhood(named: name) {
            appState.viewingNeighborhood = cached
        } else if let e = NeighborhoodDirectory.all.first(where: { $0.name.lowercased() == name.lowercased() }) {
            appState.viewingNeighborhood = Neighborhood(id: UUID(), name: e.name, shortCode: e.shortCode, borough: e.borough)
        } else {
            return
        }
        selectedNeighborhood = nil
        appState.selectedTab = 0
    }

}

// MARK: - Pulsating Pin

struct PulsatingPinView: View {
    /// Lime for corner comments, house-blue for business-tagged (Route 2).
    var tint: Color = .btLime
    /// SF Symbol shown inside the core when the pin is a tagged business.
    var symbol: String? = nil
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Invisible hit target
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
                .contentShape(Circle())

            // Outer pulse ring
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: 32, height: 32)
                .scaleEffect(isPulsing ? 1.6 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
                .allowsHitTesting(false)

            // Inner glow
            Circle()
                .fill(tint.opacity(0.3))
                .frame(width: 24, height: 24)
                .allowsHitTesting(false)

            // Core dot — a plain dot for corners, or a glyph-bearing marker for
            // tagged businesses so the map reads by type at a glance.
            Circle()
                .fill(tint)
                .frame(width: symbol != nil ? 18 : 10, height: symbol != nil ? 18 : 10)
                .overlay {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.btBg)
                    }
                }
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - House-blue "you are here" dot

struct HouseBlueDot: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.btHouse.opacity(0.18))
                .frame(width: 30, height: 30)
                .scaleEffect(isPulsing ? 1.7 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
            Circle()
                .fill(Color.btHouse)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.btHouse.opacity(0.6), radius: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    MapTabView()
        .environment(AppState())
        .environment(LocationService())
        .environment(LocalContentStore())
        .environment(NeighborhoodCache())
        .preferredColorScheme(.dark)
}
