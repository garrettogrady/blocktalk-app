import SwiftUI

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

private let onboardingUserNumber = "4,827"

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

            Text("You still post wherever you physically stand.")
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
    @State private var editing = false
    @FocusState private var fieldFocused: Bool

    private var displayName: String {
        let v = viewModel.username.trimmingCharacters(in: .whitespaces)
        return v.isEmpty ? "BlockTalker" : v
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
        case .taken:   return "That username is taken. Try another."
        case .blocked: return "That username isn't allowed."
        case .hate:    return "Watch your language. No hate speech."
        default:       return nil
        }
    }
    private var canConfirmUsername: Bool { viewModel.usernameOk }

    var body: some View {
        VStack(spacing: 0) {
            onboardingStepBar(3, 3)

            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                userNumberBanner
                heading
                if editing { usernameField }
                previewCard
            }
            .padding(.horizontal, BTSpacing.xxl)
            .padding(.top, BTSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            bottomBar
        }
        .background(Color.btBg.ignoresSafeArea())
    }

    private var userNumberBanner: some View {
        (Text("You are user: ")
            .font(BTFont.display(size: 20)).foregroundColor(Color.btText)
         + Text(onboardingUserNumber)
            .font(BTFont.monoBold(size: 19)).foregroundColor(Color.btLime))
            .tracking(-0.2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pick a username?")
                .font(BTFont.display(size: 30))
                .foregroundStyle(Color.btText)
                .tracking(-0.6)
            Text("Or stay anonymous as BlockTalker. Either way you can't be searched or followed.")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText2)
                .lineSpacing(3)
        }
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            onboardingFieldLabel("USERNAME", tag: "PERMANENT", tagColor: Color.btWarn)

            HStack(spacing: 0) {
                Text("@").font(BTFont.body(size: 15)).foregroundStyle(Color.btText3).padding(.trailing, 1)
                TextField("your username", text: $viewModel.username)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText)
                    .focused($fieldFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if viewModel.usernameOk {
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.btLime)
                } else if isErrorState {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .medium)).foregroundStyle(Color.btPink)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .background(isErrorState ? Color.btPink.opacity(0.05) : Color.btSurface)
            .cornerRadius(BTRadius.lg)
            .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(isErrorState ? Color.btPink : Color.btLine, lineWidth: 1))

            if let msg = usernameError {
                Text(msg).font(BTFont.body(size: 12)).foregroundStyle(Color.btPink)
            } else {
                Text("You're anonymous here. Don't use your real name, or anything that points back to you.")
                    .font(BTFont.body(size: 12)).foregroundStyle(Color.btText3).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text("THIS IS ALL ANYONE SEES")
                .font(BTFont.monoBold(size: 9)).tracking(1.4).foregroundStyle(Color.btText3)

            HStack(spacing: BTSpacing.sm) {
                Text("@\(displayName)")
                    .font(BTFont.bodySemibold(size: 15)).foregroundStyle(Color.btText).lineLimit(1)
                Text("#\(onboardingUserNumber)")
                    .font(BTFont.monoBold(size: 14)).foregroundStyle(Color.btLime)
                homeBadge
                Spacer(minLength: 0)
            }
            .padding(BTSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.btLime.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btLime.opacity(0.35), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        }
    }

    @ViewBuilder private var homeBadge: some View {
        if let n = appState.onboardingNeighborhood {
            HomeBadge(shortCode: n.shortCode)
        } else {
            HStack(spacing: 3) {
                Image(systemName: "house.fill").font(.system(size: 8))
                Text("—").font(BTFont.monoBold(size: 9))
            }
            .foregroundStyle(Color.btText3)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.btSurface2)
            .clipShape(Capsule())
        }
    }

    // Two explicit choices — the whole point of the split: you can't skim past
    // a field, you have to pick one.
    @ViewBuilder private var bottomBar: some View {
        VStack(spacing: BTSpacing.sm) {
            if editing {
                primaryButton(canConfirmUsername ? "Continue as @\(displayName)" : "Enter a username",
                              enabled: canConfirmUsername) {
                    finish(username: displayName)
                }
                textButton("Stay as BlockTalker instead") { finish(username: "BlockTalker") }
            } else {
                primaryButton("Set a username", enabled: true) {
                    viewModel.username = ""   // start empty — don't make them clear "BlockTalker"
                    editing = true
                    fieldFocused = true
                }
                secondaryButton("Stay anonymous as @BlockTalker") { finish(username: "BlockTalker") }
            }
        }
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.top, BTSpacing.sm)
        .padding(.bottom, BTSpacing.lg)
    }

    private func primaryButton(_ label: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(BTFont.bodyBold(size: 14)).tracking(0.4).lineLimit(1)
                .foregroundStyle(enabled ? Color.btOnAccent : Color.btText3)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(enabled ? Color.btLime : Color.btSurface2)
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

    private func textButton(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(BTFont.bodySemibold(size: 13))
                .foregroundStyle(Color.btText3)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
        }
    }

    private func finish(username: String) {
        if appState.currentUser == nil { appState.currentUser = .sample }
        appState.currentUser?.username = username
        if let hood = appState.onboardingNeighborhood {
            appState.currentUser?.homeNeighborhoodId = hood.id
            appState.viewingNeighborhood = hood
            appState.physicalNeighborhood = hood
        }
        appState.selectedTab = 0
        appState.advanceTo(.app)
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
