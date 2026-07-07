import SwiftUI

struct DailyPromptFeedView: View {
    let prompt: DailyPrompt

    @Environment(\.dismiss) private var dismiss
    @Environment(LocationService.self) private var location
    @State private var responses: [Post] = []
    @State private var archivePrompts: [DailyPrompt] = []
    @State private var showCompose = false
    @State private var showPreFrame = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Active prompt card at top
                        activePromptCard
                            .padding(BTSpacing.lg)

                        // Cross-NYC responses
                        Text("RESPONSES ACROSS NYC")
                            .font(BTFont.mono(size: 11))
                            .foregroundStyle(Color.btText3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.top, BTSpacing.md)

                        LazyVStack(spacing: 0) {
                            ForEach(responses) { post in
                                PostCard(post: post)
                                Divider().background(Color.btLine)
                            }
                        }
                        .padding(.top, BTSpacing.sm)

                        // Archive section
                        if !archivePrompts.isEmpty {
                            archiveSection
                                .padding(.top, BTSpacing.xxl)
                        }

                        Spacer(minLength: 80)
                    }
                }

                // Compose bar — replaced by the location gate when ungated
                if location.permissionState == .granted {
                    ComposeBarView {
                        showCompose = true
                    }
                } else {
                    LocationGateBar(label: "Enable location to answer the prompt", showPreFrame: $showPreFrame)
                }
            }
            .background(Color.btBg)
            .navigationTitle("Daily Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeView(nycWide: true)
            }
            .sheet(isPresented: $showPreFrame) {
                LocationPreFrameSheet()
            }
        }
    }

    // MARK: - Active Prompt Card

    private var activePromptCard: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack(spacing: BTSpacing.sm) {
                Text("TODAY'S PROMPT")
                    .font(BTFont.mono(size: 10))
                    .foregroundStyle(Color.btBg)

                HStack(spacing: BTSpacing.xs) {
                    Circle()
                        .fill(Color.btPink)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(BTFont.monoBold(size: 9))
                        .foregroundStyle(Color.btBg)
                }
                .padding(.horizontal, BTSpacing.sm)
                .padding(.vertical, BTSpacing.xs)
                .background(Color.btBg.opacity(0.15))
                .cornerRadius(BTRadius.full)

                Spacer()

                Text(prompt.timeRemaining)
                    .font(BTFont.mono(size: 10))
                    .foregroundStyle(Color.btBg.opacity(0.7))
            }

            Text(prompt.question)
                .font(BTFont.bodySemibold(size: 18))
                .foregroundStyle(Color.btBg)
                .lineSpacing(4)
        }
        .padding(BTSpacing.xl)
        .background(Color.btLime)
        .cornerRadius(BTRadius.lg)
    }

    // MARK: - Archive Section

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("PAST PROMPTS")
                .font(BTFont.mono(size: 11))
                .foregroundStyle(Color.btText3)
                .padding(.horizontal, BTSpacing.lg)

            ForEach(archivePrompts) { oldPrompt in
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    Text(oldPrompt.question)
                        .font(BTFont.bodyMedium(size: 14))
                        .foregroundStyle(Color.btText)

                    if let date = oldPrompt.createdAt {
                        Text(date, style: .date)
                            .font(BTFont.body(size: 12))
                            .foregroundStyle(Color.btText3)
                    }
                }
                .padding(BTSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.btSurface)
                .cornerRadius(BTRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.md)
                        .stroke(Color.btLine, lineWidth: 1)
                )
                .padding(.horizontal, BTSpacing.lg)
            }
        }
    }
}

#Preview {
    DailyPromptFeedView(
        prompt: DailyPrompt(
            id: UUID(),
            question: "What's the most underrated spot in your neighborhood?",
            activeFrom: Date(),
            activeUntil: Date().addingTimeInterval(3600 * 8)
        )
    )
    .preferredColorScheme(.dark)
}
