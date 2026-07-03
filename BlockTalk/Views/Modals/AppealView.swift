import SwiftUI

struct AppealView: View {
    let removedPostText: String
    let violationReason: String

    @Environment(\.dismiss) private var dismiss
    @State private var appealText = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false

    private let minLength = 20
    private let maxLength = 280

    private var canSubmit: Bool {
        let trimmed = appealText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minLength && appealText.count <= maxLength && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xxl) {
                    if showSuccess {
                        successState
                    } else {
                        formState
                    }
                }
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.top, BTSpacing.xxl)
            }
            .background(Color.btBg.ignoresSafeArea())
            .navigationTitle("Appeal Removal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
            }
        }
    }

    // MARK: - Form

    private var formState: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xl) {
            // Removed post body
            VStack(alignment: .leading, spacing: BTSpacing.sm) {
                Text("REMOVED POST")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btPink)

                Text(removedPostText)
                    .font(BTFont.body(size: 14))
                    .foregroundStyle(Color.btText2)
                    .padding(BTSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.btPink.opacity(0.08))
                    .cornerRadius(BTRadius.md)
            }

            // Violation reason
            VStack(alignment: .leading, spacing: BTSpacing.sm) {
                Text("VIOLATION")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)

                Text(violationReason)
                    .font(BTFont.bodyMedium(size: 14))
                    .foregroundStyle(Color.btText)
            }

            // Appeal textarea
            VStack(alignment: .leading, spacing: BTSpacing.sm) {
                Text("YOUR APPEAL")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)

                TextEditor(text: $appealText)
                    .font(BTFont.body(size: 15))
                    .foregroundStyle(Color.btText)
                    .scrollContentBackground(.hidden)
                    .padding(BTSpacing.md)
                    .frame(minHeight: 120)
                    .background(Color.btSurface)
                    .cornerRadius(BTRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: BTRadius.md)
                            .stroke(Color.btLine, lineWidth: 1)
                    )

                HStack {
                    if appealText.count < minLength && !appealText.isEmpty {
                        Text("At least \(minLength) characters")
                            .font(BTFont.body(size: 12))
                            .foregroundStyle(Color.btText3)
                    }
                    Spacer()
                    Text("\(appealText.count)/\(maxLength)")
                        .font(BTFont.mono(size: 11))
                        .foregroundStyle(
                            appealText.count > maxLength ? Color.btPink : Color.btText3
                        )
                }
            }

            // 48h SLA message
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.btText3)
                Text("Appeals are reviewed within 48 hours.")
                    .font(BTFont.body(size: 13))
                    .foregroundStyle(Color.btText3)
            }

            // Submit button
            Button {
                submit()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color.btBg)
                    }
                    Text("Submit Appeal")
                        .font(BTFont.bodySemibold(size: 16))
                }
                .foregroundStyle(Color.btBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BTSpacing.lg)
                .background(canSubmit ? Color.btLime : Color.btMuted)
                .cornerRadius(BTRadius.md)
            }
            .disabled(!canSubmit)
        }
    }

    // MARK: - Success

    private var successState: some View {
        VStack(spacing: BTSpacing.xl) {
            Spacer(minLength: 80)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.btLime)

            Text("Appeal submitted")
                .font(BTFont.bodySemibold(size: 18))
                .foregroundStyle(Color.btText)

            Text("We'll review your appeal within 48 hours. You'll receive a notification with the result.")
                .font(BTFont.body(size: 15))
                .foregroundStyle(Color.btText2)
                .multilineTextAlignment(.center)

            Spacer(minLength: 80)

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
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            isSubmitting = false
            showSuccess = true
        }
    }
}

#Preview {
    AppealView(
        removedPostText: "Some post that was removed for violating community guidelines.",
        violationReason: "Hate speech or slurs"
    )
    .preferredColorScheme(.dark)
}
