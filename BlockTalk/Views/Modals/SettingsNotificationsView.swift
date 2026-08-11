import SwiftUI

struct SettingsNotificationsView: View {
    @Environment(AppState.self) private var appState

    // Local cache (AppStorage) — also the offline fallback
    @AppStorage("notif_master") private var masterEnabled = true
    @AppStorage("notif_replies") private var repliesEnabled = true
    @AppStorage("notif_repliedTo") private var repliedToEnabled = true
    @AppStorage("notif_manuallyFollowed") private var manuallyFollowed = true
    @AppStorage("notif_dailyPrompt") private var dailyPromptEnabled = true
    @AppStorage("notif_moderation") private var moderationEnabled = true

    @State private var loaded = false
    private let service = NotificationPreferencesService()

    var body: some View {
        List {
            // Master switch
            Section {
                Toggle(isOn: $masterEnabled) {
                    Text("Enable Notifications")
                        .font(BTFont.bodyMedium(size: 15))
                        .foregroundStyle(Color.btText)
                }
                .tint(Color.btLime)
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)

            if masterEnabled {
                // For Your Posts
                Section {
                    Toggle(isOn: $repliesEnabled) {
                        VStack(alignment: .leading, spacing: BTSpacing.xs) {
                            Text("Replies")
                                .font(BTFont.bodyMedium(size: 15))
                                .foregroundStyle(Color.btText)
                            Text("When someone replies to your post")
                                .font(BTFont.body(size: 12))
                                .foregroundStyle(Color.btText3)
                        }
                    }
                    .tint(Color.btLime)
                } header: {
                    Text("FOR YOUR POSTS")
                        .font(BTFont.mono(size: 11))
                        .foregroundStyle(Color.btText3)
                }
                .listRowBackground(Color.btSurface)
                .listRowSeparatorTint(Color.btLine)

                // For Posts You Follow
                Section {
                    Toggle(isOn: $repliedToEnabled) {
                        VStack(alignment: .leading, spacing: BTSpacing.xs) {
                            Text("Replied-to")
                                .font(BTFont.bodyMedium(size: 15))
                                .foregroundStyle(Color.btText)
                            Text("New replies on posts you replied to")
                                .font(BTFont.body(size: 12))
                                .foregroundStyle(Color.btText3)
                        }
                    }
                    .tint(Color.btLime)

                    Toggle(isOn: $manuallyFollowed) {
                        VStack(alignment: .leading, spacing: BTSpacing.xs) {
                            Text("Manually followed")
                                .font(BTFont.bodyMedium(size: 15))
                                .foregroundStyle(Color.btText)
                            Text("Posts you subscribed to with the bell")
                                .font(BTFont.body(size: 12))
                                .foregroundStyle(Color.btText3)
                        }
                    }
                    .tint(Color.btLime)
                } header: {
                    Text("FOR POSTS YOU FOLLOW")
                        .font(BTFont.mono(size: 11))
                        .foregroundStyle(Color.btText3)
                }
                .listRowBackground(Color.btSurface)
                .listRowSeparatorTint(Color.btLine)

                // For Your Account
                Section {
                    Toggle(isOn: $dailyPromptEnabled) {
                        VStack(alignment: .leading, spacing: BTSpacing.xs) {
                            Text("Weekly prompt")
                                .font(BTFont.bodyMedium(size: 15))
                                .foregroundStyle(Color.btText)
                            Text("Sundays at 6pm, when a new prompt goes live")
                                .font(BTFont.body(size: 12))
                                .foregroundStyle(Color.btText3)
                        }
                    }
                    .tint(Color.btLime)

                    HStack {
                        VStack(alignment: .leading, spacing: BTSpacing.xs) {
                            Text("Moderation")
                                .font(BTFont.bodyMedium(size: 15))
                                .foregroundStyle(Color.btText)
                            Text("Always on for account safety")
                                .font(BTFont.body(size: 12))
                                .foregroundStyle(Color.btText3)
                        }
                        Spacer()
                        Text("LOCKED ON")
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(Color.btText3)
                            .padding(.horizontal, BTSpacing.sm)
                            .padding(.vertical, BTSpacing.xs)
                            .background(Color.btSurface2)
                            .cornerRadius(BTRadius.sm)
                    }
                } header: {
                    Text("FOR YOUR ACCOUNT")
                        .font(BTFont.mono(size: 11))
                        .foregroundStyle(Color.btText3)
                }
                .listRowBackground(Color.btSurface)
                .listRowSeparatorTint(Color.btLine)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.btBg)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadFromServer() }
        .onChange(of: masterEnabled) { _, _ in debounceSave() }
        .onChange(of: repliesEnabled) { _, _ in debounceSave() }
        .onChange(of: repliedToEnabled) { _, _ in debounceSave() }
        .onChange(of: manuallyFollowed) { _, _ in debounceSave() }
        .onChange(of: dailyPromptEnabled) { _, _ in debounceSave() }
    }

    private func loadFromServer() async {
        guard let userId = appState.currentUser?.id else { return }
        if let prefs = try? await service.fetch(userId: userId) {
            masterEnabled = prefs.masterEnabled
            repliesEnabled = prefs.replies
            repliedToEnabled = prefs.repliedTo
            manuallyFollowed = prefs.manuallyFollowed
            dailyPromptEnabled = prefs.weeklyPrompt
        }
        loaded = true
    }

    @State private var saveTask: Task<Void, Never>?

    private func debounceSave() {
        guard loaded, let userId = appState.currentUser?.id else { return }
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            let prefs = NotificationPreferences(
                userId: userId,
                masterEnabled: masterEnabled,
                replies: repliesEnabled,
                repliedTo: repliedToEnabled,
                manuallyFollowed: manuallyFollowed,
                weeklyPrompt: dailyPromptEnabled
            )
            try? await service.upsert(prefs)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsNotificationsView()
            .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
