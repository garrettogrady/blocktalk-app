import SwiftUI

struct ProfileCreationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()
    @State private var showNeighborhoodPicker = false
    @FocusState private var usernameFieldFocused: Bool

    private let userNumber = "4,827"

    var body: some View {
        VStack(spacing: 0) {
            // Step bar row
            HStack(spacing: BTSpacing.sm) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.btSurface2)
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.btLime)
                            .frame(width: geo.size.width * 0.66, height: 3)
                    }
                }
                .frame(height: 3)

                Text("02 / 03")
                    .font(BTFont.mono(size: 10))
                    .foregroundStyle(Color.btText3)
                    .tracking(1)
                    .fixedSize()
            }
            .padding(.top, BTSpacing.sm)
            .padding(.horizontal, BTSpacing.xxl)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Heading
                    HStack(spacing: 0) {
                        Text("hey ")
                            .font(BTFont.display(size: 28))
                            .foregroundStyle(Color.btText)
                        Text("city slicker")
                            .font(BTFont.display(size: 28))
                            .foregroundStyle(Color.btLime)
                    }
                    .tracking(-0.6)
                    .padding(.top, BTSpacing.xxl)

                    // Lede
                    Text("can't tell you how happy we are that you're here")
                        .font(BTFont.body(size: 13))
                        .foregroundStyle(Color.btText2)
                        .lineSpacing(4)
                        .padding(.top, BTSpacing.sm)
                        .padding(.bottom, 28)

                    // MARK: - User Number Field
                    fieldSection("USER NUMBER") {
                        HStack {
                            Text("#\(userNumber)")
                                .font(BTFont.monoBold(size: 20))
                                .foregroundStyle(Color.btLime)
                            Spacer()
                            Text("LOCKED")
                                .font(BTFont.bodySemibold(size: 9.5))
                                .foregroundStyle(Color.btText3)
                                .tracking(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.btSurface)
                        .cornerRadius(BTRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.lg)
                                .stroke(Color.btLine, lineWidth: 1)
                        )

                        Text("This number represents how many users are on our platform. It is non-editable.")
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btText2)
                            .lineSpacing(4)
                            .padding(.top, BTSpacing.sm)
                    }

                    // MARK: - Username Field
                    fieldSection("USERNAME") {
                        // Input with @ prefix and check/x icon
                        ZStack(alignment: .leading) {
                            Text("@")
                                .font(BTFont.monoBold(size: 14))
                                .foregroundStyle(Color.btText3)
                                .padding(.leading, 14)
                                .zIndex(1)

                            TextField("BlockTalker", text: $viewModel.username)
                                .font(BTFont.body(size: 14))
                                .foregroundStyle(Color.btText)
                                .padding(.horizontal, 14)
                                .padding(.leading, 16) // extra space for @
                                .padding(.vertical, 12)
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

                            // Check or X icon on the right
                            HStack {
                                Spacer()
                                if viewModel.usernameState == .valid || viewModel.usernameState == .default {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.btLime)
                                        .padding(.trailing, 14)
                                } else if isErrorState {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.btPink)
                                        .padding(.trailing, 14)
                                }
                            }
                        }
                        .background(
                            isErrorState
                                ? Color.btPink.opacity(0.05)
                                : Color.btSurface
                        )
                        .cornerRadius(BTRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.lg)
                                .stroke(
                                    isErrorState ? Color.btPink : Color.btLine,
                                    lineWidth: 1
                                )
                        )

                        // Error messages (appear ABOVE the persistent help text)
                        switch viewModel.usernameState {
                        case .invalid:
                            errorText("3–20 characters. Letters, numbers, and underscores only.")
                        case .taken:
                            errorText("That username is taken. Try another.")
                        case .blocked:
                            errorText("That username isn't allowed. Try something else.")
                        case .hate:
                            errorText("Watch your language. BlockTalk doesn't allow hate speech.")
                        default:
                            EmptyView()
                        }

                        // Persistent help text (always visible)
                        (Text("You don't need to set a username. If you skip this, you'll be shown as BlockTalker. You can set or update your username here or in Settings. Once set, your username cannot be changed. ")
                            + Text("Keep it anonymous — don't use anything personally identifiable.")
                                .font(BTFont.bodyBold(size: 13)))
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btText2)
                            .lineSpacing(4)
                            .padding(.top, BTSpacing.sm)
                    }

                    // MARK: - Home Neighborhood Field
                    fieldSection("HOME NEIGHBORHOOD") {
                        Button {
                            showNeighborhoodPicker = true
                        } label: {
                            HStack {
                                Text(viewModel.selectedNeighborhood?.name ?? "Which neighborhood do you live in?")
                                    .font(
                                        viewModel.selectedNeighborhood != nil
                                            ? BTFont.bodyMedium(size: 14)
                                            : BTFont.body(size: 14)
                                    )
                                    .foregroundStyle(
                                        viewModel.selectedNeighborhood != nil
                                            ? Color.btText
                                            : Color.btText3
                                    )
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.btText3)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.btSurface)
                            .cornerRadius(BTRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: BTRadius.lg)
                                    .stroke(Color.btLine, lineWidth: 1)
                            )
                        }

                        Text("To get the most out of BlockTalk, select the neighborhood you actually live in.")
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btText2)
                            .lineSpacing(4)
                            .padding(.top, BTSpacing.sm)
                    }

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, BTSpacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)

            // Continue button
            Button {
                handleContinue()
            } label: {
                Text("continue")
                    .font(BTFont.bodyBold(size: 13))
                    .foregroundStyle(
                        viewModel.canContinue
                            ? Color(hex: 0x0A0A0C)
                            : Color.btText3
                    )
                    .tracking(0.4)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        viewModel.canContinue
                            ? Color.btLime
                            : Color.btSurface2
                    )
                    .cornerRadius(BTRadius.lg)
            }
            .disabled(!viewModel.canContinue)
            .padding(.horizontal, BTSpacing.xxl)
            .padding(.bottom, BTSpacing.xxl)
        }
        .background(Color.btBg.ignoresSafeArea())
        .sheet(isPresented: $showNeighborhoodPicker) {
            NeighborhoodPickerView(
                currentValue: viewModel.selectedNeighborhood
            ) { neighborhood in
                viewModel.selectedNeighborhood = neighborhood
                showNeighborhoodPicker = false
            }
        }
    }

    // MARK: - Helpers

    private var isErrorState: Bool {
        switch viewModel.usernameState {
        case .taken, .invalid, .blocked, .hate:
            return true
        default:
            return false
        }
    }

    private func fieldSection(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(BTFont.bodyBold(size: 11.5))
                .foregroundStyle(Color.btText2)
                .tracking(1.6)
                .padding(.bottom, BTSpacing.sm)

            content()
        }
        .padding(.bottom, BTSpacing.xxl)
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(BTFont.body(size: 13))
            .foregroundStyle(Color.btPink)
            .lineSpacing(4)
            .padding(.top, BTSpacing.sm)
    }

    private func handleContinue() {
        guard viewModel.canContinue else { return }
        guard let neighborhood = viewModel.selectedNeighborhood else { return }

        let username = viewModel.username.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                // Use the session user ID from Apple Sign In
                guard let userId = appState.session?.user.id else {
                    print("No session — cannot create profile")
                    appState.advanceTo(.tone)
                    return
                }

                let authService = AuthService()
                try await authService.createUserProfile(
                    userId: userId,
                    username: username,
                    neighborhoodId: neighborhood.id
                )

                // Fetch the created user to populate appState
                let users: [BlockTalkUser] = try await supabase.from("users")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .execute()
                    .value

                if let user = users.first {
                    appState.currentUser = user
                }

                appState.advanceTo(.tone)
            } catch {
                print("Profile creation error: \(error)")
                // Still advance so the user isn't stuck — they can retry later
                appState.advanceTo(.tone)
            }
        }
    }
}

#Preview {
    ProfileCreationView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
