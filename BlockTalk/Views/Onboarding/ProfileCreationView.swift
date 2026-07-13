import SwiftUI

struct ProfileCreationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()
    @State private var showNeighborhoodPicker = false
    @FocusState private var usernameFieldFocused: Bool

    private let userNumber = "4,827"

    /// The name shown in the preview + CTA — falls back to the default when blank.
    private var displayName: String {
        let v = viewModel.username.trimmingCharacters(in: .whitespaces)
        return v.isEmpty ? "BlockTalker" : v
    }
    private var isDefaultName: Bool {
        displayName.caseInsensitiveCompare("BlockTalker") == .orderedSame
    }
    private enum CTAState { case fixUsername, pickNeighborhood, ready }
    private var ctaState: CTAState {
        if isErrorState { return .fixUsername }
        if viewModel.selectedNeighborhood == nil { return .pickNeighborhood }
        return .ready
    }
    /// The button states the outcome / next action — people read the CTA.
    private var ctaLabel: String {
        switch ctaState {
        case .fixUsername:      return "Continue"
        case .pickNeighborhood: return "Pick your neighborhood"
        case .ready:            return isDefaultName ? "Continue as BlockTalker" : "Continue as @\(displayName)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            stepBar

            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xl) {
                    heading
                    previewCard
                    usernameSection
                    neighborhoodSection
                    Spacer(minLength: BTSpacing.sm)
                }
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.top, BTSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)

            continueBar
        }
        .background(Color.btBg.ignoresSafeArea())
        .sheet(isPresented: $showNeighborhoodPicker) {
            NeighborhoodPickerView(
                currentValue: viewModel.selectedNeighborhood,
                confirmCta: { "Use \($0)" }
            ) { neighborhood in
                viewModel.selectedNeighborhood = neighborhood
                showNeighborhoodPicker = false
            }
        }
    }

    // MARK: - Step bar

    private var stepBar: some View {
        HStack(spacing: BTSpacing.sm) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.btSurface2).frame(height: 3)
                    RoundedRectangle(cornerRadius: 2).fill(Color.btLime)
                        .frame(width: geo.size.width * 0.66, height: 3)
                }
            }
            .frame(height: 3)
            Text("02 / 03")
                .font(BTFont.mono(size: 10)).foregroundStyle(Color.btText3).tracking(1).fixedSize()
        }
        .padding(.top, BTSpacing.sm)
        .padding(.horizontal, BTSpacing.xxl)
    }

    // MARK: - Heading

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                Text("hey ").font(BTFont.display(size: 28)).foregroundStyle(Color.btText)
                Text("city slicker").font(BTFont.display(size: 28)).foregroundStyle(Color.btLime)
            }
            .tracking(-0.6)
            Text("here's how you'll show up on the block 👇")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText2)
        }
    }

    // MARK: - Live identity preview (show, don't tell)

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Meta row — @name · #num · home badge · time
            HStack(spacing: 6) {
                Text("@\(displayName)")
                    .font(BTFont.bodySemibold(size: 12))
                    .foregroundStyle(Color.btText)
                    .lineLimit(1)
                Text("#\(userNumber)")
                    .font(BTFont.monoBold(size: 12))
                    .foregroundStyle(Color.btLime)
                homeBadge
                Text("· now").font(BTFont.mono(size: 11)).foregroundStyle(Color.btText3)
                Spacer(minLength: 0)
            }

            Text("saw something on the block worth sharing? this is where it lands.")
                .font(BTFont.body(size: 13))
                .foregroundStyle(Color.btText)
                .lineSpacing(3)

            // Faded action row so it reads as a real post
            HStack(spacing: 6) {
                fakePill("▲"); fakePill("▽")
                Spacer()
                (Text("0").foregroundStyle(Color.btText)
                 + Text(" replies").foregroundStyle(Color.btText2))
                    .font(BTFont.monoBold(size: 11))
            }
            .opacity(0.55)
        }
        .padding(BTSpacing.lg)
        .background(Color.btLime.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btLime.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
    }

    @ViewBuilder private var homeBadge: some View {
        if let n = viewModel.selectedNeighborhood {
            HomeBadge(shortCode: n.shortCode)
        } else {
            HStack(spacing: 3) {
                Image(systemName: "house.fill").font(.system(size: 8))
                Text("home").font(BTFont.monoBold(size: 9)).tracking(0.5)
            }
            .foregroundStyle(Color.btText3)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.btSurface2)
            .clipShape(Capsule())
        }
    }

    private func fakePill(_ glyph: String) -> some View {
        Text(glyph)
            .font(BTFont.bodyBold(size: 11))
            .foregroundStyle(glyph == "▲" ? Color.btLime : Color.btPink)
            .frame(width: 30, height: 30)
            .background(Color.btSurface)
            .overlay(RoundedRectangle(cornerRadius: BTRadius.sm).stroke(Color.btLine, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
    }

    // MARK: - Username

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            fieldLabel("USERNAME", tag: "OPTIONAL", tagColor: Color.btText3)

            HStack(spacing: 0) {
                // Same font as the field so the @ sits on the exact baseline.
                Text("@")
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText3)
                    .padding(.trailing, 1)

                TextField("BlockTalker", text: $viewModel.username)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText)
                    .focused($usernameFieldFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: usernameFieldFocused) { _, focused in
                        if focused && viewModel.username == "BlockTalker" {
                            viewModel.username = ""
                        } else if !focused && viewModel.username.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.username = "BlockTalker"
                        }
                    }

                if viewModel.usernameOk {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.btLime)
                } else if isErrorState {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.btPink)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(isErrorState ? Color.btPink.opacity(0.05) : Color.btSurface)
            .cornerRadius(BTRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.lg)
                    .stroke(isErrorState ? Color.btPink : Color.btLine, lineWidth: 1)
            )

            if let msg = usernameError {
                Text(msg)
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btPink)
            } else {
                Text("skip it and you're **BlockTalker** · change it anytime in Settings")
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            }
        }
    }

    // MARK: - Home neighborhood

    private var neighborhoodSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            fieldLabel("HOME NEIGHBORHOOD", tag: "REQUIRED", tagColor: Color.btLime)

            Button {
                showNeighborhoodPicker = true
            } label: {
                HStack {
                    Text(viewModel.selectedNeighborhood?.name ?? "Pick where you live")
                        .font(viewModel.selectedNeighborhood != nil
                              ? BTFont.bodyMedium(size: 15) : BTFont.body(size: 15))
                        .foregroundStyle(viewModel.selectedNeighborhood != nil ? Color.btText : Color.btText3)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 14)).foregroundStyle(Color.btText3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.btSurface)
                .cornerRadius(BTRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.lg)
                        .stroke(viewModel.selectedNeighborhood != nil ? Color.btLime.opacity(0.4) : Color.btLine, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Continue (smart CTA)

    private var continueBar: some View {
        Button {
            switch ctaState {
            case .fixUsername:      break
            case .pickNeighborhood: showNeighborhoodPicker = true
            case .ready:            handleContinue()
            }
        } label: {
            HStack(spacing: 6) {
                if ctaState == .pickNeighborhood {
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 13, weight: .semibold))
                }
                Text(ctaLabel)
                    .font(BTFont.bodyBold(size: 14))
                    .lineLimit(1)
                if ctaState == .ready {
                    Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(ctaForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(ctaState == .ready ? Color.btLime : Color.btSurface2)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.lg)
                    .stroke(ctaState == .pickNeighborhood ? Color.btLine : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        }
        .disabled(ctaState == .fixUsername)
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.top, BTSpacing.sm)
        .padding(.bottom, BTSpacing.md)
    }

    private var ctaForeground: Color {
        switch ctaState {
        case .ready:            return Color.btOnAccent
        case .pickNeighborhood: return Color.btText
        case .fixUsername:      return Color.btText3
        }
    }

    // MARK: - Helpers

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

    private func fieldLabel(_ text: String, tag: String, tagColor: Color) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(BTFont.bodyBold(size: 11.5))
                .foregroundStyle(Color.btText2)
                .tracking(1.6)
            Text(tag)
                .font(BTFont.monoBold(size: 8.5))
                .tracking(0.8)
                .foregroundStyle(tagColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(tagColor.opacity(0.14))
                .clipShape(Capsule())
        }
    }

    private func handleContinue() {
        guard viewModel.canContinue, let neighborhood = viewModel.selectedNeighborhood else { return }
        // Local mock — no backend. Ensure a user exists + set home, then advance.
        if appState.currentUser == nil { appState.currentUser = .sample }
        appState.viewingNeighborhood = neighborhood
        appState.advanceTo(.tone)
    }
}

#Preview {
    ProfileCreationView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
