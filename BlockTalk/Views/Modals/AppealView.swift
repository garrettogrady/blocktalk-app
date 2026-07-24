import SwiftUI

struct AppealView: View {
    let removedPostText: String
    let violationReason: String
    /// True when reopening a post that was already appealed — shows the locked
    /// "Already submitted. Only one appeal per post." success variant.
    var alreadyAppealed: Bool = false
    /// Fired once the appeal is actually submitted (not on cancel), so the caller
    /// can lock further appeals and post a notification.
    var onSubmitted: (() -> Void)?

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

    /// Started typing but not yet at the minimum — drives the helper text in the
    /// bottom bar (which swaps to the SLA note otherwise).
    private var needsMore: Bool {
        let trimmed = appealText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !appealText.isEmpty && trimmed.count < minLength
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xxl) {
                    if showSuccess || alreadyAppealed {
                        successState
                    } else {
                        formState
                    }
                }
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.top, BTSpacing.md)
            }
            .background(Color.btBg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if !showSuccess && !alreadyAppealed {
                    submitBar
                }
            }
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
        VStack(alignment: .leading, spacing: BTSpacing.lg) {
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
                    .frame(minHeight: 100)
                    .background(Color.btSurface)
                    .cornerRadius(BTRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: BTRadius.md)
                            .stroke(Color.btLine, lineWidth: 1)
                    )
            }
            // The character count + 48h SLA note live in the bottom bar (submitBar)
            // so they stay visible above the keyboard while typing.
        }
    }

    // MARK: - Submit bar (bottom-anchored)

    private var submitBar: some View {
        VStack(spacing: BTSpacing.sm) {
            // Count + SLA note sit here (not in the scroll body) so they stay
            // visible right above the keyboard while the user types.
            HStack(spacing: BTSpacing.sm) {
                if needsMore {
                    Text("At least \(minLength) characters")
                        .font(BTFont.body(size: 12))
                        .foregroundStyle(Color.btWarn)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.btText3)
                        Text("Appeals reviewed within 48 hours")
                            .font(BTFont.body(size: 12))
                            .foregroundStyle(Color.btText3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                Spacer()
                Text("\(appealText.count)/\(maxLength)")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(appealText.count > maxLength ? Color.btPink : Color.btText3)
            }

            Button {
                submit()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView().tint(Color.btBg)
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
        .padding(.horizontal, BTSpacing.xxl)
        .padding(.vertical, BTSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.btBg.ignoresSafeArea(.container, edges: .bottom))
    }

    // MARK: - Success

    private var successState: some View {
        // `showSuccess` = just submitted this session; otherwise it's the
        // already-appealed lock.
        let sent = showSuccess
        return VStack(spacing: BTSpacing.xl) {
            Spacer(minLength: 80)

            Image(systemName: "clock")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.btHouse)
                .frame(width: 64, height: 64)
                .background(Color.btHouse.opacity(0.12))
                .clipShape(Circle())

            Text(sent ? "Submitted." : "Already submitted.")
                .font(BTFont.bodySemibold(size: 18))
                .foregroundStyle(Color.btText)

            (Text(sent
                  ? "A human will review within "
                  : "You already appealed this one. A human is reviewing within ")
                + Text("48 hours").font(BTFont.bodySemibold(size: 15))
                + Text(sent
                       ? ". You'll get a push notification either way."
                       : ". You'll get a push notification either way. Only one appeal per post."))
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
            onSubmitted?()
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
