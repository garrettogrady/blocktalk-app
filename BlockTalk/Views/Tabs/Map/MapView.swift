import MapKit
import SwiftUI

struct MapTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @State private var viewModel = MapViewModel()
    @State private var showComposeForPin = false
    @State private var polygons: [NeighborhoodPolygon] = []
    @State private var tappedNeighborhood: String?
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
            Map(position: $cameraPosition, interactionModes: .all) {
                // Neighborhood polygon overlays
                ForEach(polygons) { polygon in
                    let isCurrent = isCurrentNeighborhood(polygon.name)
                    let isTapped = tappedNeighborhood == polygon.name
                    ForEach(Array(polygon.rings.enumerated()), id: \.offset) { _, ring in
                        MapPolygon(coordinates: ring)
                            .stroke(
                                isCurrent || isTapped
                                    ? Color.btLime
                                    : Color.white.opacity(0.22),
                                lineWidth: isCurrent || isTapped ? 1.5 : 0.9
                            )
                            .foregroundStyle(
                                isTapped
                                    ? Color.btLime.opacity(0.28)
                                    : isCurrent
                                        ? Color.btLime.opacity(0.13)
                                        : Color.white.opacity(0.04)
                            )
                    }
                }

                // Neighborhood name labels
                ForEach(polygons) { polygon in
                    let isCurrent = isCurrentNeighborhood(polygon.name)
                    Annotation("", coordinate: polygon.center) {
                        Text(polygon.name.uppercased())
                            .font(BTFont.display(size: isCurrent ? 12 : 9))
                            .tracking(1.1)
                            .foregroundStyle(isCurrent ? Color.btLime : Color.btText3)
                            .shadow(color: .black.opacity(0.85), radius: 3, x: 0, y: 0)
                            .fixedSize()
                            .onTapGesture {
                                goToNeighborhoodFeed(polygon.name)
                            }
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
            .ignoresSafeArea()
            .onMapCameraChange { context in
                viewModel.updateRadius(from: context.region)
                mapCenter = context.region.center
            }

            // Top pills
            VStack {
                if viewModel.isDropMode {
                    dropModePill
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.top, BTSpacing.sm)
                } else {
                    HStack(spacing: BTSpacing.sm) {
                        // Location pill
                        if let neighborhood = locationService.currentNeighborhood {
                            HStack(spacing: BTSpacing.xs) {
                                Circle()
                                    .fill(Color.btLime)
                                    .frame(width: 6, height: 6)
                                Text("You're in \(neighborhood.shortCode)")
                                    .font(BTFont.mono(size: 11))
                                    .foregroundStyle(Color.btText)
                                Text(viewModel.formatRadius())
                                    .font(BTFont.monoBold(size: 11))
                                    .foregroundStyle(Color.btText2)
                            }
                            .padding(.horizontal, BTSpacing.md)
                            .padding(.vertical, BTSpacing.sm)
                            .background(Color.btSurface.opacity(0.9))
                            .cornerRadius(BTRadius.full)
                        } else {
                            Text(viewModel.formatRadius())
                                .font(BTFont.mono(size: 11))
                                .foregroundStyle(Color.btText)
                                .padding(.horizontal, BTSpacing.md)
                                .padding(.vertical, BTSpacing.sm)
                                .background(Color.btSurface.opacity(0.9))
                                .cornerRadius(BTRadius.full)
                        }

                        Spacer()

                        // Hint pill
                        Text("tap a neighborhood name to open its feed")
                            .font(BTFont.body(size: 11))
                            .foregroundStyle(Color.btText2)
                            .padding(.horizontal, BTSpacing.md)
                            .padding(.vertical, BTSpacing.sm)
                            .background(Color.btSurface.opacity(0.9))
                            .cornerRadius(BTRadius.full)
                    }
                    .padding(.horizontal, BTSpacing.lg)
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

            // FAB or location gate
            if !viewModel.isDropMode {
                VStack {
                    Spacer()

                    if locationService.permissionState == .granted {
                        HStack {
                            Spacer()
                            Button {
                                viewModel.enterDropMode()
                            } label: {
                                HStack(spacing: BTSpacing.sm) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Drop a thought")
                                        .font(BTFont.bodySemibold(size: 14))
                                }
                                .foregroundStyle(Color.btBg)
                                .padding(.horizontal, BTSpacing.xl)
                                .padding(.vertical, BTSpacing.md)
                                .background(Color.btLime)
                                .cornerRadius(BTRadius.full)
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            }
                        }
                        .padding(.horizontal, BTSpacing.lg)
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
                pinDropLocation: mapCenter
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

    private func isCurrentNeighborhood(_ polygonName: String) -> Bool {
        let pName = polygonName.lowercased()
        // Check GPS-resolved neighborhood
        if let current = locationService.currentNeighborhood {
            if pName == current.name.lowercased() || pName == current.shortCode.lowercased() {
                return true
            }
        }
        // Also check the actively viewed neighborhood
        if let viewing = appState.viewingNeighborhood {
            if pName == viewing.name.lowercased() || pName == viewing.shortCode.lowercased() {
                return true
            }
        }
        return false
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

    private func goToNeighborhoodFeed(_ name: String) {
        tappedNeighborhood = name
        // Find the matching neighborhood from polygons and resolve it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            tappedNeighborhood = nil
            // Look up the neighborhood from Supabase by name
            Task {
                do {
                    let results: [Neighborhood] = try await supabase.from("neighborhoods")
                        .select("id, name, short_code, borough")
                        .ilike("name", value: name)
                        .limit(1)
                        .execute()
                        .value
                    if let neighborhood = results.first {
                        appState.viewingNeighborhood = neighborhood
                        appState.selectedTab = 0 // Switch to Feed
                    }
                } catch {
                    print("Failed to find neighborhood '\(name)': \(error)")
                }
            }
        }
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
