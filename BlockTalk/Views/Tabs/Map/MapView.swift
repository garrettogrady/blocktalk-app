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

                // Lime label follows the highlighted neighborhood (selected if the
                // user tapped one, otherwise the one they're in). Every other name
                // comes from the base map — rendering our own duplicated them.
                ForEach(polygons.filter { $0.name == (selectedNeighborhood ?? activeNeighborhoodName) }) { polygon in
                    Annotation("", coordinate: polygon.center) {
                        Text(polygon.name.uppercased())
                            .font(BTFont.display(size: 12))
                            .tracking(1.1)
                            .foregroundStyle(Color.btLime)
                            .shadow(color: .black.opacity(0.85), radius: 3, x: 0, y: 0)
                            .fixedSize()
                    }
                }

                // Pin annotations (bundled samples + anything created this session)
                ForEach(viewModel.pins + localContent.pins) { pin in
                    Annotation("", coordinate: pin.coordinate) {
                        PulsatingPinView()
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
                viewModel.updateRadius(from: context.region)
                mapCenter = context.region.center
            }
            // Tap to select; tap the selected one again to open its feed; tap
            // empty water/far away to deselect. Skips taps on a pin.
            .onTapGesture { screenPoint in
                guard !viewModel.isDropMode,
                      let coord = proxy.convert(screenPoint, from: .local),
                      !isNearPin(coord) else { return }
                handleTap(at: coord)
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
                                Text("·").foregroundStyle(Color.btText3)
                                Text(viewModel.formatRadius())
                                    .font(BTFont.monoBold(size: 11))
                                    .foregroundStyle(Color.btLime)
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

                        // Hint pill — centered, below
                        Text("tap a neighborhood to select it")
                            .font(BTFont.body(size: 11))
                            .foregroundStyle(Color.btText2)
                            .padding(.horizontal, BTSpacing.md)
                            .padding(.vertical, BTSpacing.xs)
                            .background(Color.btSurface.opacity(0.9))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, BTSpacing.sm)
                }

                Spacer()
            }

            // Drop mode overlay
            if viewModel.isDropMode {
                PinDropOverlay()

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
                            // Recenter to your postable zone so the reticle starts
                            // in-range even if you'd panned off to browse elsewhere.
                            selectedNeighborhood = nil
                            focus(on: activeNeighborhoodName)
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
        .sheet(isPresented: $showComposeForPin) {
            ComposeView(
                postingNeighborhood: appState.physicalNeighborhood ?? locationService.currentNeighborhood,
                pinDropLocation: mapCenter,
                pinCornerName: snappedCorner(mapCenter)
            )
        }
        .sheet(isPresented: $showPreFrame) {
            LocationPreFrameSheet()
        }
        .sheet(item: $selectedPinDetail) { detail in
            NavigationStack {
                // Same detail view as the feed, so a street comment looks
                // identical whether opened from the map or the feed.
                PostDetailView(post: detail.post)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                selectedPinDetail = nil
                            } label: {
                                HStack(spacing: BTSpacing.xs) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Pin · \(detail.pin.cornerName ?? "Drop")")
                                        .font(BTFont.bodySemibold(size: 16))
                                }
                                .foregroundStyle(Color.btText)
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
        focus(on: activeNeighborhoodName)
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
    private var dropInRange: Bool {
        let highlighted = polygons.filter { isCurrentNeighborhood($0.name) }
        guard !highlighted.isEmpty else { return true }
        return highlighted.contains { $0.contains(mapCenter) }
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
        let corner = snappedCorner(mapCenter)
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
                        Text("\(talkingCount(name)) talking")
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

    /// A stable, made-up "N talking" count per neighborhood so the map feels
    /// alive. Deterministic from the name (no backend). [PROD-DIFF]
    private func talkingCount(_ name: String) -> Int {
        let base = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return base % 180 + 14
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

    /// Open the confirmed neighborhood's feed — resolved locally from the
    /// bundled directory (no backend). Switches to the Feed tab.
    private func openFeed(_ name: String) {
        guard let e = NeighborhoodDirectory.all.first(where: { $0.name.lowercased() == name.lowercased() })
        else { return }
        appState.viewingNeighborhood = Neighborhood(id: UUID(), name: e.name, shortCode: e.shortCode, borough: e.borough)
        selectedNeighborhood = nil
        appState.selectedTab = 0
    }

}

// MARK: - Pulsating Pin

struct PulsatingPinView: View {
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
                .fill(Color.btLime.opacity(0.15))
                .frame(width: 32, height: 32)
                .scaleEffect(isPulsing ? 1.6 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
                .allowsHitTesting(false)

            // Inner glow
            Circle()
                .fill(Color.btLime.opacity(0.3))
                .frame(width: 24, height: 24)
                .allowsHitTesting(false)

            // Core dot
            Circle()
                .fill(Color.btLime)
                .frame(width: 10, height: 10)
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
        .preferredColorScheme(.dark)
}
