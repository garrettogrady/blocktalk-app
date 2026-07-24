import SwiftUI

struct SettingsProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showDeleteConfirm = false
    @State private var showSetUsername = false

    /// Still on the default handle → they haven't set a username yet, so they can.
    private var canSetUsername: Bool {
        (appState.currentUser?.username ?? "BlockTalker")
            .caseInsensitiveCompare("BlockTalker") == .orderedSame
    }

    var body: some View {
        List {
            // Identity section
            Section {
                // User number
                HStack {
                    Text("User #")
                        .font(BTFont.bodyMedium(size: 15))
                        .foregroundStyle(Color.btText)
                    Spacer()
                    if let user = appState.currentUser {
                        Text("#\(user.userNumber.formatted(.number))")
                            .font(BTFont.mono(size: 14))
                            .foregroundStyle(Color.btText2)
                    }
                    chip("LOCKED")
                }

                // Username — settable once if you're still BlockTalker, else locked.
                Button {
                    if canSetUsername { showSetUsername = true }
                } label: {
                    HStack {
                        Text("Username")
                            .font(BTFont.bodyMedium(size: 15))
                            .foregroundStyle(Color.btText)
                        Spacer()
                        if let user = appState.currentUser {
                            Text("@\(user.username)")
                                .font(BTFont.bodyMedium(size: 14))
                                .foregroundStyle(Color.btText2)
                        }
                        if canSetUsername {
                            Text("SET →").font(BTFont.bodySemibold(size: 12)).foregroundStyle(Color.btLime)
                        } else {
                            chip("LOCKED")
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSetUsername)

                // Neighborhood with UNLOCKS chip
                HStack {
                    Text("Neighborhood")
                        .font(BTFont.bodyMedium(size: 15))
                        .foregroundStyle(Color.btText)
                    Spacer()
                    HStack(spacing: BTSpacing.sm) {
                        Text("UNLOCKS")
                            .font(BTFont.mono(size: 9))
                            .foregroundStyle(Color.btWarn)
                            .padding(.horizontal, BTSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.btWarn.opacity(0.15))
                            .cornerRadius(BTRadius.sm)

                        Text("30d")
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btText3)
                    }
                }
            } header: {
                Text("IDENTITY")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            } footer: {
                Text(ProfileCopy.usernameGuide)
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)

            // Danger Zone
            Section {
                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Text("Delete Account")
                            .font(BTFont.bodyMedium(size: 15))
                            .foregroundStyle(Color.btPink)
                        Spacer()
                        Image(systemName: "trash")
                            .foregroundStyle(Color.btPink)
                    }
                }
            } header: {
                Text("DANGER ZONE")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btPink)
            }
            .listRowBackground(Color.btPink.opacity(0.08))
            .listRowSeparatorTint(Color.btLine)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.btBg)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete your BlockTalk account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                appState.signOut()
            }
        } message: {
            Text("Any posts you've made will remain on the platform under the BlockTalker placeholder.")
        }
        .sheet(isPresented: $showSetUsername) {
            SetUsernameSheet()
        }
    }

    private func chip(_ text: String, tone: Color = .btText3) -> some View {
        Text(text)
            .font(BTFont.monoBold(size: 9))
            .tracking(0.8)
            .foregroundStyle(tone)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, 2)
            .background(tone.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Set username (once) from Settings

/// Lets a still-BlockTalker user set their permanent username later. Same rules
/// and copy as onboarding (ProfileCopy).
struct SetUsernameSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProfileViewModel()
    @FocusState private var focused: Bool

    private var displayName: String {
        let v = viewModel.username.trimmingCharacters(in: .whitespaces)
        return v.isEmpty ? "" : v
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

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: BTSpacing.lg) {
                Text("Set your username")
                    .font(BTFont.display(size: 24)).foregroundStyle(Color.btText).tracking(-0.5)

                HStack(spacing: 0) {
                    Text("@").font(BTFont.body(size: 15)).foregroundStyle(Color.btText3).padding(.trailing, 1)
                    TextField("your username", text: $viewModel.username)
                        .font(BTFont.body(size: 15)).foregroundStyle(Color.btText)
                        .focused($focused)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
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

                Text(usernameError ?? ProfileCopy.usernameGuide)
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(usernameError == nil ? Color.btText3 : Color.btPink)
                    .lineSpacing(3).fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    appState.currentUser?.username = displayName
                    dismiss()
                } label: {
                    Text("Set @\(displayName.isEmpty ? "username" : displayName)")
                        .font(BTFont.bodyBold(size: 14)).tracking(0.4).lineLimit(1)
                        .foregroundStyle(Color.btOnAccent.opacity(viewModel.usernameOk ? 1 : 0.65))
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.btLime.opacity(viewModel.usernameOk ? 1 : 0.4))
                        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
                }
                .disabled(!viewModel.usernameOk)
            }
            .padding(BTSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.btBg.ignoresSafeArea())
            .navigationTitle("Username")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.btText2)
                }
            }
            .onAppear { focused = true }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack {
        SettingsProfileView()
            .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
