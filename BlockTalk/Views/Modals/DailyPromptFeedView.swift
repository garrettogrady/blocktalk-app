import SwiftUI

struct DailyPromptFeedView: View {
    let prompt: DailyPrompt

    @Environment(\.dismiss) private var dismiss
    @Environment(LocationService.self) private var location
    @State private var showCompose = false
    @State private var showPreFrame = false
    @State private var expandedArchive: UUID?

    private let responses = DailyPrompt.sampleResponses
    private let archive = DailyPrompt.sampleArchive

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        activeCard

                        // Cross-NYC responses
                        LazyVStack(spacing: 0) {
                            ForEach(responses) { post in
                                PostCard(post: post)
                                Divider().background(Color.btLine)
                            }
                        }

                        archiveSection
                            .padding(.top, BTSpacing.xxl)

                        Spacer(minLength: 100)
                    }
                }

                // Compose bar (gated when location off)
                if location.permissionState == .granted {
                    promptComposeBar
                } else {
                    LocationGateBar(label: "Enable location to answer the prompt", showPreFrame: $showPreFrame)
                }
            }
            .background(Color.btBg)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) { header }
            .sheet(isPresented: $showCompose) { ComposeView(nycWide: true) }
            .sheet(isPresented: $showPreFrame) { LocationPreFrameSheet() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: BTSpacing.md) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.btText)
                    .frame(width: 38, height: 38)
                    .background(Color.btSurface)
                    .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY'S PROMPT · NYC-WIDE")
                    .font(BTFont.monoBold(size: 10)).tracking(1)
                    .foregroundStyle(Color.btLime)
                Text("Prompt of the day")
                    .font(BTFont.display(size: 24))
                    .foregroundStyle(Color.btText)
            }
            Spacer()
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.btBg)
    }

    // MARK: - Active prompt card (dark tinted strip)

    private var activeCard: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack {
                HStack(spacing: BTSpacing.xs) {
                    Circle().fill(Color.btLime).frame(width: 6, height: 6)
                    Text("LIVE · \(prompt.timeRemaining)")
                        .font(BTFont.monoBold(size: 11)).tracking(0.5)
                        .foregroundStyle(Color.btLime)
                }
                Spacer()
                Text("NYC-WIDE")
                    .font(BTFont.monoBold(size: 9))
                    .foregroundStyle(Color.btHouse)
                    .padding(.horizontal, BTSpacing.sm).padding(.vertical, 3)
                    .overlay(Capsule().stroke(Color.btHouse.opacity(0.4), lineWidth: 1))
                    .clipShape(Capsule())
            }

            Text("\u{201C}\(prompt.question)\u{201D}")
                .font(BTFont.display(size: 22))
                .foregroundStyle(Color.btText)
                .lineSpacing(3)

            HStack(spacing: 0) {
                Text("\(DailyPrompt.sampleAnswerCount.formatted())").foregroundStyle(Color.btLime)
                Text(" answers across NYC").foregroundStyle(Color.btText2)
            }
            .font(BTFont.monoBold(size: 12))
        }
        .padding(BTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btLime.opacity(0.06))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.btLime.opacity(0.18)).frame(height: 1)
        }
    }

    // MARK: - Archive

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack(spacing: BTSpacing.xs) {
                Image(systemName: "lock.fill").font(.system(size: 11))
                Text("ARCHIVE").font(BTFont.monoBold(size: 11)).tracking(1.2)
            }
            .foregroundStyle(Color.btText3)
            .padding(.horizontal, BTSpacing.lg)

            Text("past prompts · locked from new answers")
                .font(BTFont.body(size: 12))
                .foregroundStyle(Color.btText3)
                .padding(.horizontal, BTSpacing.lg)

            ForEach(archive) { a in
                archiveCard(a).padding(.horizontal, BTSpacing.lg)
            }
        }
    }

    private func archiveCard(_ a: PromptArchive) -> some View {
        let expanded = expandedArchive == a.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expandedArchive = expanded ? nil : a.id }
            } label: {
                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    HStack {
                        Text(a.date).font(BTFont.monoBold(size: 9)).tracking(1).foregroundStyle(Color.btText3)
                        Spacer()
                        Text("LOCKED · NO NEW ANSWERS")
                            .font(BTFont.monoBold(size: 8.5))
                            .foregroundStyle(Color.btWarn)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .overlay(Capsule().stroke(Color.btWarn.opacity(0.4), lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    Text(a.question)
                        .font(BTFont.bodySemibold(size: 14))
                        .foregroundStyle(Color.btText)
                        .multilineTextAlignment(.leading)
                    HStack {
                        Text("\(a.answerCount) answers").font(BTFont.body(size: 11)).foregroundStyle(Color.btText3)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.system(size: 11)).foregroundStyle(Color.btText3)
                    }
                }
                .padding(BTSpacing.lg)
            }
            .buttonStyle(.plain)

            if expanded {
                ForEach(a.posts) { post in
                    Divider().background(Color.btLine)
                    PostCard(post: post)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }

    // MARK: - Compose bar

    private var promptComposeBar: some View {
        VStack(spacing: BTSpacing.sm) {
            Divider().background(Color.btLine)

            HStack(spacing: BTSpacing.xs) {
                Circle().fill(Color.btLime).frame(width: 6, height: 6)
                (Text("Posting to ").foregroundColor(.btText2)
                 + Text("TODAY'S PROMPT").foregroundColor(.btText)
                 + Text(" · NYC-WIDE").foregroundColor(.btText2))
                    .font(BTFont.bodySemibold(size: 10.5))
                Spacer()
            }
            .padding(.horizontal, BTSpacing.lg)

            Button { showCompose = true } label: {
                HStack(spacing: BTSpacing.md) {
                    Text("Answer the prompt…")
                        .font(BTFont.body(size: 15))
                        .foregroundStyle(Color.btText3)
                    Spacer()
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.btOnAccent)
                        .frame(width: 38, height: 38)
                        .background(Color.btLime)
                        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                }
                .padding(.leading, BTSpacing.md)
                .background(Color.btSurface)
                .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                .padding(.horizontal, BTSpacing.lg)
            }
            .buttonStyle(.plain)
            .padding(.bottom, BTSpacing.sm)
        }
        .background {
            Color.btBg.ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

#Preview {
    DailyPromptFeedView(prompt: DailyPrompt.sampleActive)
        .environment(LocationService())
        .preferredColorScheme(.dark)
}
