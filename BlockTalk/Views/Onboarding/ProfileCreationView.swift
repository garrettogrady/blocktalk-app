import SwiftUI
import UIKit

/// Copy shared between onboarding and Settings so the username rules never
/// contradict each other.
enum ProfileCopy {
    static let usernameGuide = "BlockTalk is anonymous. Don't use your real name, or anything that points back to you. You can only set a username once, and it can't be changed."
    static let aliasGuide = "No real names, nothing traceable — that's the whole point of this place."
    static let locationRule = "You post wherever you're physically located."
}

/// Generates anonymous, NYC-flavored aliases (e.g. "orchard_ghost", "feral_pigeon").
/// It only SUGGESTS — uniqueness is guaranteed server-side (ProfileViewModel checks
/// the users table). The big word lists keep clean two-word handles common for early
/// users; a number suffix is the fallback once the clean space fills, so it never runs
/// dry at scale (words × words × numbers ≈ millions). [PROD: the server appends a
/// number or re-suggests when a generated alias collides with an existing one.]
enum AliasGenerator {
    // Streets, neighborhoods, transit, NYC texture.
    private static let places = [
        "orchard", "ludlow", "delancey", "rivington", "stanton", "essex", "allen", "bowery",
        "canal", "mott", "mulberry", "houston", "clinton", "norfolk", "forsyth", "chrystie",
        "grand", "hester", "broome", "spring", "prince", "bleecker", "macdougal", "astor",
        "dyckman", "bushwick", "ridgewood", "astoria", "flatbush", "gowanus", "greenpoint",
        "bedstuy", "harlem", "inwood", "chelsea", "tribeca", "soho", "nolita", "dumbo",
        "redhook", "canarsie", "flushing", "corona", "rockaway", "fordham", "pelham",
        "ftrain", "ltrain", "gtrain", "jtrain", "atrain", "qtrain", "crosstown", "uptown",
        "downtown", "midtown", "bodega", "deli", "stoop", "hydrant", "walkup", "rooftop",
        "alley", "gutter", "curb", "turnstile", "platform", "subway", "express", "halalcart",
    ]
    // Creatures + NYC archetypes + mythic.
    private static let characters = [
        "rat", "ratking", "pigeon", "roach", "raccoon", "possum", "squirrel", "seagull",
        "waterbug", "alleycat", "ghost", "menace", "saint", "prophet", "oracle", "gremlin",
        "wraith", "hermit", "mayor", "villain", "phantom", "lurker", "sage", "goblin",
        "specter", "baron", "duke", "hustler", "myth", "legend", "native", "transplant",
        "local", "regular", "insomniac", "nightowl", "wanderer", "drifter", "sentinel",
        "watcher", "bard", "poet", "critic", "skeptic", "truther", "whisperer", "snob",
        "renegade", "outlaw", "bandit", "banshee", "gargoyle", "vagrant", "stray", "recluse",
        "enigma", "cryptid", "apostle",
    ]
    // Flavor adjectives for extra variety.
    private static let adjectives = [
        "feral", "nocturnal", "unbothered", "chronic", "reluctant", "humble", "restless",
        "weary", "jaded", "hungover", "crosstown", "downtown", "uptown", "perpetual",
    ]

    /// One alias, lowercase, obeying the app's [a-z0-9_] 3–20 rule.
    static func generate() -> String {
        for _ in 0..<12 {
            let candidate = build()
            if (3...20).contains(candidate.count) { return candidate }
        }
        return "\(pick(places))\(number())"   // guaranteed-valid fallback
    }

    private static func build() -> String {
        switch Int.random(in: 0..<20) {
        case 0..<8:   return "\(pick(places))_\(pick(characters))"              // orchard_ghost
        case 8..<13:  return "\(pick(adjectives))_\(pick(characters))"          // feral_pigeon
        case 13..<17: return "\(pick(characters))_\(pick(places))"              // baron_bowery
        default:      return "\(pick(places))_\(pick(characters))_\(number())"  // + number
        }
    }
    private static func pick(_ list: [String]) -> String { list.randomElement() ?? "block" }
    private static func number() -> String { String(Int.random(in: 2...99)) }
}

// MARK: - Shared onboarding chrome

/// Progress bar used by both profile steps (fill = current/total).
private func onboardingStepBar(_ current: Int, _ total: Int) -> some View {
    HStack(spacing: BTSpacing.sm) {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.btSurface2).frame(height: 3)
                RoundedRectangle(cornerRadius: 2).fill(Color.btLime)
                    .frame(width: geo.size.width * CGFloat(current) / CGFloat(total), height: 3)
            }
        }
        .frame(height: 3)
        Text(String(format: "%02d / %02d", current, total))
            .font(BTFont.mono(size: 10)).foregroundStyle(Color.btText3).tracking(1).fixedSize()
    }
    .padding(.top, BTSpacing.sm)
    .padding(.horizontal, BTSpacing.xxl)
}

private func onboardingFieldLabel(_ text: String, tag: String, tagColor: Color) -> some View {
    HStack(spacing: 7) {
        Text(text)
            .font(BTFont.bodyBold(size: 13)).foregroundStyle(Color.btText).tracking(1.4)
        Text(tag)
            .font(BTFont.monoBold(size: 9.5)).tracking(0.9).foregroundStyle(tagColor)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(tagColor.opacity(0.18)).clipShape(Capsule())
    }
}

// MARK: - Step 1: Home neighborhood

struct ProfileCreationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()
    @State private var showNeighborhoodPicker = false

    private var hasNeighborhood: Bool { viewModel.selectedNeighborhood != nil }

    var body: some View {
        VStack(spacing: 0) {
            onboardingStepBar(2, 3)

            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                heading
                neighborhoodSection
            }
            .padding(.horizontal, BTSpacing.xxl)
            .padding(.top, BTSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            continueBar
        }
        .background(Color.btBg.ignoresSafeArea())
        .fullScreenCover(isPresented: $showNeighborhoodPicker) {
            NeighborhoodPickerView(
                currentValue: viewModel.selectedNeighborhood,
                confirmCta: { "Use \($0)" }
            ) { neighborhood in
                viewModel.selectedNeighborhood = neighborhood
                showNeighborhoodPicker = false
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Where are you based?")
                .font(BTFont.display(size: 30))
                .foregroundStyle(Color.btText)
                .tracking(-0.6)
            Text("Pick your home neighborhood. It's your badge and the feed you land in.")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText2)
                .lineSpacing(3)
        }
    }

    private var neighborhoodSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            onboardingFieldLabel("HOME NEIGHBORHOOD", tag: "REQUIRED", tagColor: Color.btLime)

            Button {
                showNeighborhoodPicker = true
            } label: {
                HStack(spacing: BTSpacing.md) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(hasNeighborhood ? Color.btText2 : Color.btLime)
                    if let n = viewModel.selectedNeighborhood {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(n.name).font(BTFont.bodyMedium(size: 16)).foregroundStyle(Color.btText)
                            Text(n.borough.uppercased())
                                .font(BTFont.monoBold(size: 8.5)).tracking(0.8).foregroundStyle(Color.btText3)
                        }
                    } else {
                        Text("Tap to pick where you live")
                            .font(BTFont.body(size: 15)).foregroundStyle(Color.btText3)
                    }
                    Spacer()
                    Image(systemName: hasNeighborhood ? "checkmark" : "chevron.down")
                        .font(.system(size: 14, weight: hasNeighborhood ? .semibold : .regular))
                        .foregroundStyle(hasNeighborhood ? Color.btLime : Color.btText3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Color.btSurface)
                .cornerRadius(BTRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.lg)
                        .stroke(Color.btLime.opacity(hasNeighborhood ? 0.4 : 0.5), lineWidth: 1)
                )
            }

            Text("You still post wherever you're physically located.")
                .font(BTFont.body(size: 12)).foregroundStyle(Color.btText3)
        }
    }

    private var continueBar: some View {
        Button {
            if hasNeighborhood {
                appState.onboardingNeighborhood = viewModel.selectedNeighborhood
                appState.advanceTo(.username)
            } else {
                showNeighborhoodPicker = true
            }
        } label: {
            Text(hasNeighborhood ? "Continue" : "Pick your neighborhood")
                .font(BTFont.bodyBold(size: 14))
                .tracking(0.4)
                .lineLimit(1)
                .foregroundStyle(hasNeighborhood ? Color.btOnAccent : Color.btText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(hasNeighborhood ? Color.btLime : Color.btSurface2)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.lg)
                        .stroke(hasNeighborhood ? Color.clear : Color.btLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        }
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.top, BTSpacing.sm)
        .padding(.bottom, BTSpacing.lg)
    }
}

// MARK: - Step 2: Username (a forced choice, not a skippable field)

struct UsernameCreationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()
    @FocusState private var fieldFocused: Bool
    /// Surfaced if the final profile insert fails — otherwise "Continue" looks
    /// dead and the user is stranded on the last onboarding screen.
    @State private var saveError: String?

    private var displayName: String {
        viewModel.username.trimmingCharacters(in: .whitespaces)
    }
    private var isErrorState: Bool {
        switch viewModel.usernameState {
        case .taken, .invalid, .blocked, .hate: return true
        default: return false
        }
    }
    private var usernameError: String? {
        switch viewModel.usernameState {
        case .invalid: return "3–20 characters · letters, numbers, underscores"
        case .taken:   return "That alias is taken. Shuffle or tweak it."
        case .blocked: return "That alias isn't allowed."
        case .hate:    return "Watch your language. No hate speech."
        default:       return nil
        }
    }
    private var canConfirm: Bool { viewModel.usernameState == .valid }

    var body: some View {
        VStack(spacing: 0) {
            onboardingStepBar(3, 3)

            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xl) {
                    userNumberBanner
                    heading
                    aliasField
                }
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.top, BTSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.btBg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomBar }
        .onAppear {
            // Everyone starts with a generated NYC alias — no "BlockTalker" default.
            if viewModel.username.caseInsensitiveCompare("BlockTalker") == .orderedSame {
                shuffle()
            }
        }
        .onChange(of: viewModel.username) { _, _ in
            viewModel.checkUsernameTaken()
        }
        .alert("Couldn't finish setting up", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Something went wrong. Check your connection and try again.")
        }
    }

    // Was "You are user: 4,827" — a hardcoded fake shown to every signup. The
    // real user number is a DB sequence assigned at account creation (shown on
    // your profile after onboarding), so we don't invent one here.
    private var userNumberBanner: some View {
        (Text("You're in. ")
            .font(BTFont.display(size: 20)).foregroundColor(Color.btText)
         + Text("Now pick your alias.")
            .font(BTFont.display(size: 20)).foregroundColor(Color.btLime))
            .tracking(-0.2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var heading: some View {
        Text("Set an alias. Not your name.")
            .font(BTFont.display(size: 30))
            .foregroundStyle(Color.btText)
            .tracking(-0.5)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var aliasField: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            onboardingFieldLabel("YOUR ALIAS", tag: "ANONYMOUS", tagColor: Color.btLime)

            HStack(spacing: BTSpacing.sm) {
                Text("@").font(BTFont.body(size: 15)).foregroundStyle(Color.btText3)
                TextField("your alias", text: $viewModel.username)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText)
                    .focused($fieldFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if viewModel.usernameState == .valid {
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.btLime)
                } else if isErrorState {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.btPink)
                }
                // Shuffle a fresh NYC alias
                Button { shuffle() } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.btLime)
                        .padding(.leading, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .background(isErrorState ? Color.btPink.opacity(0.05) : Color.btSurface)
            .cornerRadius(BTRadius.lg)
            .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(isErrorState ? Color.btPink : Color.btLine, lineWidth: 1))

            if let msg = usernameError {
                Text(msg).font(BTFont.body(size: 12)).foregroundStyle(Color.btPink)
            } else {
                Text(ProfileCopy.aliasGuide)
                    .font(BTFont.body(size: 12)).foregroundStyle(Color.btText3).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // Everyone leaves with an alias — the generated one, an edit of it, or a
    // fresh shuffle. No "BlockTalker" default to skim past.
    private var bottomBar: some View {
        VStack(spacing: BTSpacing.sm) {
            primaryButton(canConfirm ? "Continue as @\(displayName)" : "Continue",
                          enabled: canConfirm) {
                finish(username: displayName)
            }
            secondaryButton("Shuffle a new one") { shuffle() }
        }
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.top, BTSpacing.sm)
        .padding(.bottom, BTSpacing.lg)
    }

    private func shuffle() {
        viewModel.username = AliasGenerator.generate()
    }

    // Disabled state dims the lime (keeps it reading as the SAME button), never
    // greys out — the format shouldn't change when you tap into the field.
    private func primaryButton(_ label: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(BTFont.bodyBold(size: 14)).tracking(0.4).lineLimit(1)
                .foregroundStyle(Color.btOnAccent.opacity(enabled ? 1 : 0.65))
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color.btLime.opacity(enabled ? 1 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        }
        .disabled(!enabled)
    }

    private func secondaryButton(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(BTFont.bodyBold(size: 14)).tracking(0.4).lineLimit(1)
                .foregroundStyle(Color.btText)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color.btSurface)
                .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btLine, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        }
    }

    private func finish(username: String) {
        fieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        guard let userId = appState.session?.user.id else {
            print("Cannot finish onboarding: no authenticated session")
            return
        }
        guard let hood = appState.onboardingNeighborhood else {
            print("Cannot finish onboarding: no neighborhood selected")
            return
        }

        Task {
            do {
                // If the picker fell back to the local directory, the ID is a
                // random UUID. Resolve the REAL Supabase ID by name so the DB
                // always stores a valid foreign key.
                var resolvedHood = hood
                let service = NeighborhoodService()
                if let realHood = try? await service.fetchByName(hood.name) {
                    resolvedHood = realHood
                }

                let authService = AuthService()
                try await authService.createUserProfile(
                    userId: userId,
                    username: username,
                    neighborhoodId: resolvedHood.id
                )

                // Fetch the created user back to get server-generated fields
                let users: [BlockTalkUser] = try await supabase.from("users")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .execute()
                    .value

                guard let user = users.first else { return }

                appState.currentUser = user
                appState.viewingNeighborhood = resolvedHood
                if appState.physicalNeighborhood == nil {
                    appState.physicalNeighborhood = resolvedHood
                }
                appState.hasResolvedInitialNeighborhood = true
                appState.selectedTab = 0
                appState.advanceTo(.app)
            } catch {
                print("Failed to create user profile: \(error)")
                await MainActor.run {
                    saveError = "We couldn't create your profile. That alias may have just been taken — try Shuffle, or check your connection."
                }
            }
        }
    }
}

#Preview("Step 1 — Neighborhood") {
    ProfileCreationView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Step 2 — Username") {
    UsernameCreationView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
