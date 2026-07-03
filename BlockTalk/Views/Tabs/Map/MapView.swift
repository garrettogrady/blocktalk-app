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

                // User location
                UserAnnotation()
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
                    if !viewModel.isDropMode {
                        Text("tap a neighborhood name to open its feed")
                            .font(BTFont.body(size: 11))
                            .foregroundStyle(Color.btText2)
                            .padding(.horizontal, BTSpacing.md)
                            .padding(.vertical, BTSpacing.sm)
                            .background(Color.btSurface.opacity(0.9))
                            .cornerRadius(BTRadius.full)
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
                .padding(.top, BTSpacing.sm)

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
                            showComposeForPin = true
                        } label: {
                            Text("Drop here")
                                .font(BTFont.bodySemibold(size: 15))
                                .foregroundStyle(Color.btBg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BTSpacing.md)
                                .background(Color.btLime)
                                .cornerRadius(BTRadius.md)
                        }
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
                        // Location gate for map
                        Button {
                            locationService.requestPermission()
                        } label: {
                            HStack(spacing: BTSpacing.sm) {
                                Image(systemName: "location.slash")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Enable location to post")
                                    .font(BTFont.bodySemibold(size: 14))
                            }
                            .foregroundStyle(Color.btBg)
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

#Preview {
    MapTabView()
        .environment(AppState())
        .environment(LocationService())
        .preferredColorScheme(.dark)
}
