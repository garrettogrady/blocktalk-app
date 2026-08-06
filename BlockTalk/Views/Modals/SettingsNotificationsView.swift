import SwiftUI

struct SettingsNotificationsView: View {
    // Persisted so a toggle survives navigation + relaunch (was @State → a no-op
    // that reset on nav-away). Push delivery will read these once the backend
    // notification stack exists; until then they at least persist the intent.
    @AppStorage("notif_master") private var masterEnabled = true
    @AppStorage("notif_replies") private var repliesEnabled = true
    @AppStorage("notif_repliedTo") private var repliedToEnabled = true
    @AppStorage("notif_manuallyFollowed") private var manuallyFollowed = true
    @AppStorage("notif_dailyPrompt") private var dailyPromptEnabled = true
    @AppStorage("notif_moderation") private var moderationEnabled = true

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
    }
}

#Preview {
    NavigationStack {
        SettingsNotificationsView()
    }
    .preferredColorScheme(.dark)
}
