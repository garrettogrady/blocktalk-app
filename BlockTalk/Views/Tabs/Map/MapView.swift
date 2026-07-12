import MapKit
import SwiftUI

struct MapTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @State private var viewModel = MapViewModel()
    @State private var showComposeForPin = false
    @State private var polygons: [NeighborhoodPolygon] = []
    /// The neighborhood the user tapped — highlighted + named in a bottom card,
    /// pending confirmation. Tap-to-select-then-confirm (not instant navigate).
    @State private var selectedNeighborhood: String?
    @State private var selectedPinDetail: (pin: Pin, post: Post)?
    @State private var showPinDetail = false
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
                                isSelected || isCurrent ? Color.btLime : Color.white.opacity(0.22),
                                lineWidth: isSelected ? 2.5 : (isCurrent ? 1.5 : 0.9)
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

                // Pin annotations
                ForEach(viewModel.pins) { pin in
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
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)
            .onMapCameraChange { context in
                viewModel.updateRadius(from: context.region)
                mapCenter = context.region.center
            }
            // Tap anywhere to SELECT that neighborhood (it highlights + a card
            // names it). Works at any zoom: exact hit, else snap to the nearest
            // neighborhood so a tap is never dead. Skips taps on a pin.
            .onTapGesture { screenPoint in
                guard !viewModel.isDropMode,
                      let coord = proxy.convert(screenPoint, from: .local),
                      !isNearPin(coord) else { return }
                if let name = neighborhood(at: coord) {
                    withAnimation(.easeOut(duration: 0.15)) { selectedNeighborhood = name }
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
                        // "You're in" pill — top-centered
                        HStack(spacing: BTSpacing.xs) {
                            Circle().fill(Color.btLime).frame(width: 6, height: 6)
                            Text("You're in \(hereShortCode)")
                                .font(BTFont.bodySemibold(size: 12))
                                .foregroundStyle(Color.btText)
                            Text("·").foregroundStyle(Color.btText3)
                            Text(viewModel.formatRadius())
                                .font(BTFont.monoBold(size: 11))
                                .foregroundStyle(Color.btLime)
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
                            if dropInRange { showComposeForPin = true }
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
                        // Location gate FAB — routes through the shared pre-frame
                        Button {
                            locationGateTap(locationService, showPreFrame: $showPreFrame)
                        } label: {
                            HStack(spacing: BTSpacing.sm) {
                                Image(systemName: "location.slash")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(locationService.permissionState == .denied
                                     ? "Open Settings · location off"
                                     : "Enable location to post")
                                    .font(BTFont.bodySemibold(size: 14))
                            }
                            .foregroundStyle(Color.btOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BTSpacing.md)
                            .background(Color.btWarn)
                            .cornerRadius(BTRadius.full)
                        }
                        .padding(.horizontal, BTSpacing.xxl)
                        .padding(.bottom, BTSpacing.xxxl)
                    }
                }
            }
        }
        .sheet(isPresented: $showComposeForPin) {
            ComposeView(
                postingNeighborhood: appState.viewingNeighborhood ?? locationService.currentNeighborhood,
                pinDropLocation: mapCenter,
                pinCornerName: snappedCorner(mapCenter)
            )
        }
        .sheet(isPresented: $showPreFrame) {
            LocationPreFrameSheet()
        }
        .sheet(isPresented: $showPinDetail) {
            if let detail = selectedPinDetail {
                NavigationStack {
                    PinDetailView(pin: detail.pin, post: detail.post)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    showPinDetail = false
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
        }
        .onChange(of: appState.pendingPinPlacement) { _, pending in
            // Compose switched to pin mode → auto-enter drop mode
            if pending {
                selectedNeighborhood = nil
                viewModel.enterDropMode()
                appState.pendingPinPlacement = false
            }
        }
        .task {
            polygons = NeighborhoodPolygonLoader.load()
            await viewModel.loadNeighborhoods()
            await viewModel.loadAllPins()
        }
    }

    // MARK: - Helpers

    /// The single active neighborhood (only this one is highlighted). Uses the
    /// viewing neighborhood (reliable locally), falling back to GPS-resolved,
    /// then LES — never highlights two at once.
    private var activeNeighborhoodName: String {
        appState.viewingNeighborhood?.name ?? locationService.currentNeighborhood?.name ?? "Lower East Side"
    }

    private var hereShortCode: String {
        appState.viewingNeighborhood?.shortCode ?? locationService.currentNeighborhood?.shortCode ?? "NYC"
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
                    if let boro {
                        Text(boro.uppercased())
                            .font(BTFont.monoBold(size: 9))
                            .tracking(1.2)
                            .foregroundStyle(Color.btText3)
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
        Task {
            do {
                let postService = PostService()
                if let post = try await postService.fetchPostForPin(pin.id) {
                    selectedPinDetail = (pin: pin, post: post)
                    showPinDetail = true
                }
            } catch {
                print("Failed to load post for pin: \(error)")
            }
        }
    }

    /// Which neighborhood a tapped coordinate belongs to: the polygon that
    /// contains it, else the nearest one (so a tap in a gap/near an edge still
    /// selects something sensible instead of doing nothing).
    private func neighborhood(at coord: CLLocationCoordinate2D) -> String? {
        if let hit = polygons.first(where: { $0.contains(coord) }) { return hit.name }
        return polygons.min(by: {
            distance(coord, $0.center) < distance(coord, $1.center)
        })?.name
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
