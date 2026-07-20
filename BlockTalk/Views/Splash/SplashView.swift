import AuthenticationServices
import MapKit
import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            // MapKit background locked to Lower Manhattan. contentMargins lifts
            // Apple's required logo/Legal up above the sign-in + legal footer so
            // it stays fully visible and isn't clipped (App Store rule).
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7193, longitude: -73.9911),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.024)
            )), interactionModes: []) {
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

                // Value prop — big enough that a first-timer instantly gets it
                Text("anonymous NYC commentary")
                    .font(BTFont.displayMedium(size: 21))
                    .foregroundStyle(Color.btText)
                    .tracking(-0.2)
                    .padding(.bottom, 6)
                Text("neighborhood-locked · post where you stand")
                    .font(BTFont.body(size: 12.5))
                    .foregroundStyle(Color.btText2)
                    .tracking(0.4)
                    .padding(.bottom, BTSpacing.xxxl)

                // Labels the card below as a sample so it's not mistaken for a control
                Text("this is what a post looks like")
                    .font(BTFont.mono(size: 10.5))
                    .foregroundStyle(Color.btText3)
                    .tracking(0.4)
                    .padding(.bottom, BTSpacing.sm)

                // Hero card with sample post
                heroCard
                    .padding(.bottom, BTSpacing.xxxl)

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
        appState.advanceTo(.tone)   // the one rule comes first, then profile
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
                            // New user — the one rule first, then profile creation
                            appState.advanceTo(.tone)
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
