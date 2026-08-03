import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var text = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var submitError: String?

    private let minLength = 10
    private let maxLength = 1500

    private var canSubmit: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minLength && text.count <= maxLength && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: BTSpacing.xxl) {
                if showSuccess {
                    successState
                } else {
                    formState
                }
            }
            .padding(.horizontal, BTSpacing.xxl)
            .background(Color.btBg.ignoresSafeArea())
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
            }
        }
    }

    // MARK: - Form

    private var formState: some View {
        VStack(alignment: .leading, spacing: BTSpacing.lg) {
            Text("What's on your mind?")
                .font(BTFont.bodySemibold(size: 17))
                .foregroundStyle(Color.btText)
                .padding(.top, BTSpacing.xxl)

            Text("Bug reports, feature requests, or anything else.")
                .font(BTFont.body(size: 14))
                .foregroundStyle(Color.btText2)

            // Multiline input
            TextEditor(text: $text)
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText)
                .scrollContentBackground(.hidden)
                .padding(BTSpacing.md)
                .frame(minHeight: 160)
                .background(Color.btSurface)
                .cornerRadius(BTRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.md)
                        .stroke(Color.btLine, lineWidth: 1)
                )

            // Character count
            HStack {
                if text.count < minLength && !text.isEmpty {
                    Text("At least \(minLength) characters")
                        .font(BTFont.body(size: 12))
                        .foregroundStyle(Color.btText3)
                }
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(
                        text.count > maxLength ? Color.btPink : Color.btText3
                    )
            }

            // Privacy note
            HStack(alignment: .top, spacing: BTSpacing.sm) {
                Image(systemName: "lock")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.btText3)
                Text("Your user # is attached so we can follow up if needed. Nothing else.")
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            }

            if let submitError {
                Text(submitError)
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btPink)
            }

            Spacer()

            // Submit button
            Button {
                submit()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color.btBg)
                    }
                    Text("Send Feedback")
                        .font(BTFont.bodySemibold(size: 16))
                }
                .foregroundStyle(Color.btBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BTSpacing.lg)
                .background(canSubmit ? Color.btLime : Color.btMuted)
                .cornerRadius(BTRadius.md)
            }
            .disabled(!canSubmit)
            .padding(.bottom, BTSpacing.md)
        }
    }

    // MARK: - Success

    private var successState: some View {
        VStack(spacing: BTSpacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.btLime)

            Text("Got it.")
                .font(BTFont.bodySemibold(size: 18))
                .foregroundStyle(Color.btText)

            Text("We read every message. We don't reply individually — but if it changes something, you'll see it.")
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText2)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(BTFont.bodySemibold(size: 16))
                    .foregroundStyle(Color.btBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.lg)
                    .background(Color.btLime)
                    .cornerRadius(BTRadius.md)
            }
            .padding(.bottom, BTSpacing.xxxl)
        }
    }

    private func submit() {
        guard let userId = appState.currentUser?.id else { return }
        isSubmitting = true
        submitError = nil
        Task {
            do {
                try await supabase.from("feedback")
                    .insert(["user_id": userId.uuidString,
                             "body": text.trimmingCharacters(in: .whitespacesAndNewlines)])
                    .execute()
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    submitError = "Failed to send. Check your connection."
                }
            }
        }
    }
}

#Preview {
    FeedbackView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
