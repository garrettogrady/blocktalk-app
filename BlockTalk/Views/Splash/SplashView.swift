import AuthenticationServices
import MapKit
import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            // MapKit background locked to Lower Manhattan
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7193, longitude: -73.9911),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.024)
            )), interactionModes: []) {
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .ignoresSafeArea()
            .colorScheme(.dark)

            // 50% black scrim
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                HStack(spacing: 0) {
                    Text("block")
                        .font(BTFont.display(size: 72))
                        .foregroundStyle(Color.btText)
                        .minimumScaleFactor(0.6)
                    Text(".")
                        .font(BTFont.display(size: 72))
                        .foregroundStyle(Color.btLime)
                        .minimumScaleFactor(0.6)
                    Text("talk")
                        .font(BTFont.display(size: 72))
                        .foregroundStyle(Color.btText)
                        .minimumScaleFactor(0.6)
                }
                .padding(.bottom, BTSpacing.sm)

                // Subheader
                Text("anonymous · neighborhood-locked · NYC")
                    .font(BTFont.bodyBold(size: 11))
                    .foregroundStyle(Color.btText)
                    .tracking(1.6)
                    .padding(.bottom, BTSpacing.xxxl)

                // Hero card with sample post
                heroCard
                    .padding(.bottom, BTSpacing.xxxl)

                Spacer()

                // Apple Sign In button
                #if targetEnvironment(simulator)
                // Simulator bypass — Apple Sign In doesn't work in the Simulator
                Button {
                    appState.advanceTo(.profile)
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                            .font(BTFont.bodySemibold(size: 17))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white)
                    .cornerRadius(BTRadius.md)
                }
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.bottom, BTSpacing.lg)
                #else
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    handleSignIn(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.bottom, BTSpacing.lg)
                #endif

                // Legal text
                Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                    .font(BTFont.body(size: 11))
                    .foregroundStyle(Color.btText3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BTSpacing.xxxl)
                    .padding(.bottom, BTSpacing.xxl)
            }
        }
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
            Text("the F train at 6:14pm is doing something supernatural. doors close, lights flicker, a man starts humming. same thing every tuesday.")
                .font(BTFont.body(size: 18))
                .foregroundStyle(Color.btText)
                .lineSpacing(4)

            // Stats row
            HStack(spacing: BTSpacing.lg) {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.btText3)

                Text("41 replies")
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)

                Spacer()
            }
            .padding(.top, BTSpacing.xs)
        }
        .padding(BTSpacing.lg)
        .background(Color(hex: 0x0E0E11, opacity: 0.94))
        .cornerRadius(BTRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.lg)
                .stroke(Color.btLine, lineWidth: 1)
        )
        .padding(.horizontal, BTSpacing.xxl)
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
                            // New user — go to profile creation
                            appState.advanceTo(.profile)
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
