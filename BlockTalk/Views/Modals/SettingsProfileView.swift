import SwiftUI

struct SettingsProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showDeleteConfirm = false

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

                // Username
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
                    chip("LOCKED")
                }

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
                Text("Must be unique. Once set, it cannot be changed.")
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

#Preview {
    NavigationStack {
        SettingsProfileView()
            .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
