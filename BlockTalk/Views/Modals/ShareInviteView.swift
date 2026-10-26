import SwiftUI

struct ShareInviteView: View {
    @State private var codes: [InviteCode] = []
    @State private var isGenerating = false
    @State private var error: String?
    @State private var showShareSheet = false
    @State private var shareCode: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                header

                generateButton

                if let error {
                    Text(error)
                        .font(BTFont.body(size: 13))
                        .foregroundStyle(.red)
                }

                if !codes.isEmpty {
                    codesList
                }
            }
            .padding(BTSpacing.xl)
        }
        .background(Color.btBg.ignoresSafeArea())
        .navigationTitle("Invite Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadCodes() }
        .sheet(isPresented: $showShareSheet) {
            if let shareCode {
                ShareSheet(items: [shareMessage(for: shareCode)])
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text("INVITE FRIENDS")
                .font(BTFont.monoBold(size: 12))
                .foregroundStyle(Color.btLime)
                .tracking(2)

            Text("BlockTalk is invite-only. Share a code with someone to let them in.")
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText2)
                .lineSpacing(3)
        }
    }

    private var generateButton: some View {
        Button {
            generateAndShare()
        } label: {
            HStack(spacing: BTSpacing.sm) {
                if isGenerating {
                    ProgressView().tint(Color.btOnAccent)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Generate & Share Invite")
                        .font(BTFont.bodyBold(size: 14))
                        .tracking(0.3)
                }
            }
            .foregroundStyle(Color.btOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.btLime)
            .cornerRadius(BTRadius.lg)
        }
        .disabled(isGenerating)
    }

    private var codesList: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("YOUR INVITES")
                .font(BTFont.monoBold(size: 11))
                .foregroundStyle(Color.btText3)
                .tracking(2)

            ForEach(codes) { code in
                codeRow(code)
            }
        }
    }

    private func codeRow(_ code: InviteCode) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(code.code)
                    .font(BTFont.monoBold(size: 16))
                    .foregroundStyle(code.isRedeemed ? Color.btText3 : Color.btText)
                    .tracking(2)

                Text(code.isRedeemed ? "Used" : "Available")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(code.isRedeemed ? Color.btText3 : Color.btLime)
            }

            Spacer()

            if !code.isRedeemed {
                Button {
                    shareCode = code.code
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.btLime)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.md)
    }

    private func shareMessage(for code: String) -> String {
        """
        Join me on BlockTalk — the anonymous, hyperlocal app for NYC neighborhoods. \
        Talk about where you actually are.

        1. Download BlockTalk from the App Store
        2. Sign in with Apple
        3. Enter this invite code: \(code)

        See you on the block!
        """
    }

    private func generateAndShare() {
        isGenerating = true
        error = nil
        Task {
            do {
                let code: String = try await supabase.rpc("generate_invite_code").execute().value
                await MainActor.run {
                    isGenerating = false
                    shareCode = code
                    showShareSheet = true
                }
                await loadCodes()
            } catch {
                await MainActor.run {
                    isGenerating = false
                    if error.localizedDescription.contains("invite_limit") {
                        self.error = "You have 5 unused invites. Share or wait for one to be used."
                    } else {
                        self.error = "Couldn't generate invite. Check your connection."
                    }
                }
            }
        }
    }

    private func loadCodes() async {
        let loaded: [InviteCode]? = try? await supabase.from("invite_codes")
            .select("id, code, redeemed_by, created_at")
            .eq("created_by", value: (try? await supabase.auth.session).map { $0.user.id.uuidString } ?? "")
            .order("created_at", ascending: false)
            .execute()
            .value
        await MainActor.run {
            codes = loaded ?? []
        }
    }
}

private struct InviteCode: Identifiable, Codable {
    let id: UUID
    let code: String
    let redeemedBy: UUID?
    let createdAt: Date

    var isRedeemed: Bool { redeemedBy != nil }

    enum CodingKeys: String, CodingKey {
        case id, code
        case redeemedBy = "redeemed_by"
        case createdAt = "created_at"
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
