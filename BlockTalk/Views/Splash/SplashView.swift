import AuthenticationServices
import MapKit
import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState

    // Landing composition — flip these two to swap the hero. Easy revert:
    // set showHeroCard = true / showStreetPins = false to restore the
    // sample-post card. [Matt: keep reversible]
    private let showHeroCard = false
    private let showStreetPins = true

    // A few LES corners, south of the map center so the pins sit in the open
    // lower-middle of the screen (below the logo, above sign-in). One is a
    // business-tagged gym (house-blue, dumbbell) to preview Route 2.
    private struct LandingPin {
        let coord: CLLocationCoordinate2D
        let tint: Color
        let symbol: String?
    }
    // 6 house-blue business pins on REAL Lower East Side businesses (each a
    // distinct type/icon, Route 2), plus 12 lime corner pins scattered around.
    private let landingPins: [LandingPin] = [
        // Vital — gym. Reads the same Pin.vital used by the map + feed, so the
        // location and dumbbell icon can never drift between screens.
        .init(coord: Pin.vital.coordinate, tint: .btHouse, symbol: Pin.vital.placeSymbol),
        // Katz's Delicatessen — restaurant (205 E Houston St)
        .init(coord: .init(latitude: 40.72225, longitude: -73.98748), tint: .btHouse, symbol: "fork.knife"),
        // Tenement Museum — museum (103 Orchard St)
        .init(coord: .init(latitude: 40.71882, longitude: -73.99009), tint: .btHouse, symbol: "building.columns.fill"),
        // Pianos — bar (158 Ludlow St)
        .init(coord: .init(latitude: 40.72100, longitude: -73.98780), tint: .btHouse, symbol: "wineglass.fill"),
        // Doughnut Plant — bakery (379 Grand St)
        .init(coord: .init(latitude: 40.71629, longitude: -73.98856), tint: .btHouse, symbol: "birthday.cake.fill"),
        // Round K — café (99 Allen St)
        .init(coord: .init(latitude: 40.71820, longitude: -73.99060), tint: .btHouse, symbol: "cup.and.saucer.fill"),

        // 12 corner/street comments scattered across the WHOLE visible map —
        // west (Village/SoHo), north (NoHo/EV), and south (Chinatown), not just
        // the LES cluster, so the page feels alive everywhere.
        .init(coord: .init(latitude: 40.72800, longitude: -73.99950), tint: .btLime, symbol: nil), // West Village
        .init(coord: .init(latitude: 40.72480, longitude: -73.99750), tint: .btLime, symbol: nil), // Village
        .init(coord: .init(latitude: 40.72250, longitude: -73.99980), tint: .btLime, symbol: nil), // SoHo
        .init(coord: .init(latitude: 40.71950, longitude: -73.99850), tint: .btLime, symbol: nil), // SoHo / LES west
        .init(coord: .init(latitude: 40.72880, longitude: -73.99000), tint: .btLime, symbol: nil), // NoHo
        .init(coord: .init(latitude: 40.72950, longitude: -73.98380), tint: .btLime, symbol: nil), // East Village
        .init(coord: .init(latitude: 40.72580, longitude: -73.98600), tint: .btLime, symbol: nil), // East Village
        .init(coord: .init(latitude: 40.72120, longitude: -73.98900), tint: .btLime, symbol: nil), // Nolita / LES
        .init(coord: .init(latitude: 40.71820, longitude: -73.98320), tint: .btLime, symbol: nil), // LES east
        .init(coord: .init(latitude: 40.71520, longitude: -73.99450), tint: .btLime, symbol: nil), // Chinatown
        .init(coord: .init(latitude: 40.71380, longitude: -73.99900), tint: .btLime, symbol: nil), // Tribeca / Chinatown
        .init(coord: .init(latitude: 40.71680, longitude: -73.98780), tint: .btLime, symbol: nil), // LES south
    ]

    var body: some View {
        ZStack {
            // MapKit background locked to Lower Manhattan. contentMargins lifts
            // Apple's required logo/Legal up above the sign-in + legal footer so
            // it stays fully visible and isn't clipped (App Store rule).
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7193, longitude: -73.9911),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.024)
            )), interactionModes: []) {
                if showStreetPins {
                    ForEach(Array(landingPins.enumerated()), id: \.offset) { i, p in
                        Annotation("", coordinate: p.coord) {
                            PulsingStreetPin(tint: p.tint, symbol: p.symbol, delay: Double(i % 6) * 0.3)
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls { }
            // Keep Apple's logo/Legal at the true bottom-left of the screen, just
            // clear of the home indicator, so it's visible but not clipped. The
            // app's legal footer is lifted above it so they don't collide.
            .contentMargins(.bottom, 16, for: .automatic)
            .ignoresSafeArea()
            .colorScheme(.dark)

            // Scrim — darker at the bottom for text legibility, lighter mid-screen
            // so the lifted Apple logo stays readable.
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                HStack(spacing: 0) {
                    Text("block")
                        .foregroundStyle(Color.btText)
                    Text(".")
                        .foregroundStyle(Color.btLime)
                    Text("talk")
                        .foregroundStyle(Color.btText)
                }
                .font(BTFont.display(size: 84))
                .tracking(-3)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.bottom, BTSpacing.sm)

                // The one line that says what the app is
                Text("anonymous NYC commentary")
                    .font(BTFont.displayMedium(size: 22))
                    .foregroundStyle(Color.btText)
                    .tracking(-0.2)
                    .offset(y: -13)
                    .padding(.bottom, BTSpacing.xxxl)

                // Hero card with sample post — hidden for now in favor of the
                // pulsing street pins on the map. Flip showHeroCard to restore.
                if showHeroCard {
                    heroCard
                        .padding(.bottom, BTSpacing.xxxl)
                }

                Spacer()

                // Apple Sign In. Real auth is production; the Simulator can't do it,
                // and "Replay onboarding" forces the bypass so the demo can walk the
                // full splash → onboarding flow on-device.
                #if targetEnvironment(simulator)
                appleSignInButton { startOnboarding() }
                #else
                if appState.forceOnboarding {
                    appleSignInButton { startOnboarding() }
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email]
                    } onCompletion: { result in
                        handleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, BTSpacing.xxl)
                    .padding(.bottom, BTSpacing.lg)
                }
                #endif

                // Legal text — lifted above Apple's bottom-left logo/Legal strip.
                Text(legalText)
                    .font(BTFont.body(size: 10))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BTSpacing.xxxl)
                    .padding(.bottom, 46)
            }
        }
    }

    // Verbatim RN legal line; "terms" and "community rules" read as links.
    private var legalText: AttributedString {
        var s = AttributedString("by continuing you agree to our terms & community rules.")
        s.foregroundColor = .btText2
        if let r = s.range(of: "terms") { s[r].foregroundColor = .btText }
        if let r = s.range(of: "community rules") { s[r].foregroundColor = .btText }
        return s
    }

    // MARK: - Vote Pill

    private func votePill(glyph: String, color: Color) -> some View {
        Text(glyph)
            .font(BTFont.bodyBold(size: 12))
            .foregroundStyle(color)
            .frame(height: 30)
            .padding(.horizontal, BTSpacing.md)
            .background(Color.btSurface)
            .overlay(Capsule().stroke(Color.btLine, lineWidth: 1))
            .clipShape(Capsule())
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Meta row
            HStack(spacing: BTSpacing.xs) {
                Text("@streetrat")
                    .font(BTFont.bodySemibold(size: 13))
                    .foregroundStyle(Color.btText)
                Text("·")
                    .foregroundStyle(Color.btText3)
                Text("#4,827")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btLime)
                Text("·")
                    .foregroundStyle(Color.btText3)
                HomeBadge(shortCode: "LES")
                Text("·")
                    .foregroundStyle(Color.btText3)
                Text("22m ago")
                    .font(BTFont.body(size: 11))
                    .foregroundStyle(Color.btText3)
                Spacer()
            }

            // Post body
            Text("the F train at 6:14pm is doing something supernatural and i'm starting to take it personally")
                .font(BTFont.body(size: 18))
                .foregroundStyle(Color.btText)
                .lineSpacing(4)

            // Action row — lime ▲ / pink ▽ pills + reply count
            HStack(spacing: BTSpacing.sm) {
                votePill(glyph: "▲", color: .btLime)
                votePill(glyph: "▽", color: .btPink)
                Spacer()
                HStack(spacing: 0) {
                    Text("41")
                        .foregroundStyle(Color.btText)
                    Text(" replies")
                        .foregroundStyle(Color.btText2)
                }
                .font(BTFont.monoBold(size: 12))
            }
            .padding(.top, BTSpacing.xs)
        }
        .padding(BTSpacing.lg)
        .background(Color.btSurface.opacity(0.94))
        .cornerRadius(BTRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.lg)
                .stroke(Color.btLine, lineWidth: 1)
        )
        .padding(.horizontal, BTSpacing.xxl)
    }

    // MARK: - Sign In

    /// White Apple-styled button used for the Simulator + onboarding-replay bypass.
    private func appleSignInButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "apple.logo")
                Text("Sign in with Apple").font(BTFont.bodySemibold(size: 17))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.white)
            .cornerRadius(BTRadius.md)
        }
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.bottom, BTSpacing.lg)
    }

    private func startOnboarding() {
        appState.forceOnboarding = false
        appState.advanceTo(.how)   // how it works → the one rule → profile
    }

    // MARK: - Sign In Handler

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    do {
                        let authService = AuthService()
                        let session = try await authService.signInWithApple(credential: credential)
                        appState.session = session

                        // Check if user profile already exists
                        let existing: [BlockTalkUser] = try await supabase.from("users")
                            .select()
                            .eq("id", value: session.user.id.uuidString)
                            .execute()
                            .value

                        if let user = existing.first {
                            // Returning user — skip onboarding
                            appState.currentUser = user
                            appState.advanceTo(.app)
                        } else {
                            // New user — how it works, then the rule, then profile
                            appState.advanceTo(.how)
                        }
                    } catch {
                        print("Sign in error: \(error)")
                    }
                }
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error)")
        }
    }
}

#Preview {
    SplashView()
        .environment(AppState())
}

// MARK: - Pulsing street pin (landing map)

/// A street-comment pin for the landing map: a solid lime dot with a ring that
/// pulses outward, staggered per pin via `delay`.
private struct PulsingStreetPin: View {
    var tint: Color = .btLime
    var symbol: String? = nil
    var delay: Double = 0
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.35))
                .frame(width: 40, height: 40)
                .scaleEffect(animate ? 1.7 : 0.5)
                .opacity(animate ? 0 : 0.7)
            Circle()
                .fill(tint)
                .frame(width: symbol != nil ? 20 : 11, height: symbol != nil ? 20 : 11)
                .overlay {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.btBg)
                    }
                }
                .overlay(Circle().stroke(Color.black.opacity(0.55), lineWidth: 1.5))
                .shadow(color: tint.opacity(0.6), radius: 5)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false).delay(delay)) {
                animate = true
            }
        }
    }
}
