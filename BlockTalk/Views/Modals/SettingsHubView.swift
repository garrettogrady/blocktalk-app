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
}

#Preview {
    NavigationStack {
        SettingsHubView()
    }
    .preferredColorScheme(.dark)
}
