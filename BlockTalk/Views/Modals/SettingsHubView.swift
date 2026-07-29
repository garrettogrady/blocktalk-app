import SwiftUI

struct SettingsHubView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Account section
            Section {
                NavigationLink {
                    SettingsProfileView()
                } label: {
                    settingsRow(icon: "person.circle", title: "Profile")
                }

                NavigationLink {
                    SettingsNotificationsView()
                } label: {
                    settingsRow(icon: "bell", title: "Notifications")
                }
            } header: {
                Text("ACCOUNT")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)

            #if DEBUG
            // Testing tools — only visible in debug builds
            Section {
                NavigationLink {
                    SettingsTestingView()
                } label: {
                    settingsRow(icon: "ant", title: "Testing")
                }
            } header: {
                Text("DEVELOPER")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btWarn)
            }
            .listRowBackground(Color.btWarn.opacity(0.08))
            .listRowSeparatorTint(Color.btLine)
            #endif

            // About section
            Section {
                HStack(spacing: BTSpacing.md) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.btText2)
                        .frame(width: 24)
                    Text("Version")
                        .font(BTFont.bodyMedium(size: 15))
                        .foregroundStyle(Color.btText)
                    Spacer()
                    Text(appVersion)
                        .font(BTFont.mono(size: 13))
                        .foregroundStyle(Color.btText3)
                }

                NavigationLink {
                    LegalTextView(title: "Privacy Policy")
                } label: {
                    settingsRow(icon: "hand.raised", title: "Privacy Policy")
                }

                NavigationLink {
                    LegalTextView(title: "Terms of Service")
                } label: {
                    settingsRow(icon: "doc.text", title: "Terms of Service")
                }
            } header: {
                Text("ABOUT")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.btBg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Color.btText2)
            }
        }
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.btText2)
                .frame(width: 24)
            Text(title)
                .font(BTFont.bodyMedium(size: 15))
                .foregroundStyle(Color.btText)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }
}

/// Lightweight placeholder for Privacy Policy / Terms so the rows aren't dead
/// taps. Real copy gets dropped in before launch.
struct LegalTextView: View {
    let title: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.lg) {
                Text(title)
                    .font(BTFont.display(size: 24))
                    .foregroundStyle(Color.btText)
                Text("The full \(title.lowercased()) is being finalized ahead of launch. BlockTalk is anonymous and neighborhood-locked: we don't sell your data, and your exact location is never shown to anyone.")
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText2)
                    .lineSpacing(5)
                Text("Questions? Reach us through Settings → Send Feedback.")
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText2)
                    .lineSpacing(5)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BTSpacing.xxl)
        }
        .background(Color.btBg.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SettingsHubView()
    }
    .preferredColorScheme(.dark)
}
