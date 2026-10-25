import SwiftUI

struct InviteCodeView: View {
    @Environment(AppState.self) private var appState
    @State private var code = ""
    @State private var isValidating = false
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EARLY ACCESS")
                .font(BTFont.monoBold(size: 13))
                .foregroundStyle(Color.btLime)
                .tracking(3)
                .padding(.bottom, BTSpacing.lg)

            Text("Enter your\ninvite code.")
                .font(BTFont.display(size: 34))
                .foregroundStyle(Color.btText)
                .tracking(-0.8)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("BlockTalk is invite-only right now. Enter the code you received to get started.")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText2)
                .padding(.top, BTSpacing.md)

            Spacer(minLength: BTSpacing.xl)

            VStack(spacing: BTSpacing.md) {
                TextField("", text: $code, prompt: Text("CODE").foregroundStyle(Color.btText3))
                    .font(BTFont.monoBold(size: 20))
                    .foregroundStyle(Color.btText)
                    .tracking(4)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.vertical, BTSpacing.lg)
                    .background(Color.btSurface2)
                    .cornerRadius(BTRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: BTRadius.lg)
                            .stroke(error != nil ? Color.red.opacity(0.6) : Color.btLine, lineWidth: 1)
                    )
                    .focused($focused)

                if let error {
                    Text(error)
                        .font(BTFont.body(size: 13))
                        .foregroundStyle(.red)
                }
            }

            Spacer(minLength: BTSpacing.xl)

            Button {
                validateCode()
            } label: {
                Group {
                    if isValidating {
                        ProgressView().tint(Color.btOnAccent)
                    } else {
                        Text("Continue")
                            .font(BTFont.bodyBold(size: 14))
                            .tracking(0.4)
                    }
                }
                .foregroundStyle(Color.btOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(code.trimmingCharacters(in: .whitespaces).isEmpty ? Color.btSurface2 : Color.btLime)
                .cornerRadius(BTRadius.lg)
            }
            .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
        }
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.top, BTSpacing.xxxl)
        .padding(.bottom, BTSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.btBg.ignoresSafeArea())
        .onAppear { focused = true }
    }

    private func validateCode() {
        guard let userId = appState.session?.user.id else { return }
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isValidating = true
        error = nil

        Task {
            do {
                let result: Bool = try await supabase.rpc(
                    "redeem_invite_code",
                    params: ["p_code": trimmed, "p_user_id": userId.uuidString]
                ).execute().value

                await MainActor.run {
                    isValidating = false
                    if result {
                        appState.advanceTo(.how)
                    } else {
                        error = "Invalid or already used code."
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    self.error = "Couldn't verify code. Check your connection."
                }
            }
        }
    }
}
