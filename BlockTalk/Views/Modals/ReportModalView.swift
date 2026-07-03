import SwiftUI

struct ReportModalView: View {
    let postId: UUID

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ReportReason?
    @State private var freeText = ""
    @State private var isSubmitting = false
    @State private var error: String?

    private let freeTextMin = 10
    private let freeTextMax = 140

    private var canSubmit: Bool {
        guard let reason = selectedReason, !isSubmitting else { return false }
        if reason == .other {
            let trimmed = freeText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.count >= freeTextMin && freeText.count <= freeTextMax
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xxl) {
                    Text("Why are you reporting this post?")
                        .font(BTFont.bodySemibold(size: 17))
                        .foregroundStyle(Color.btText)
                        .padding(.top, BTSpacing.xxl)

                    // 6 reason picker
                    VStack(spacing: BTSpacing.sm) {
                        ForEach(ReportReason.allCases) { reason in
                            reasonRow(reason)
                        }
                    }

                    // Free text for "other"
                    if selectedReason == .other {
                        VStack(alignment: .leading, spacing: BTSpacing.sm) {
                            Text("Please describe the issue")
                                .font(BTFont.body(size: 13))
                                .foregroundStyle(Color.btText2)

                            TextEditor(text: $freeText)
                                .font(BTFont.body(size: 15))
                                .foregroundStyle(Color.btText)
                                .scrollContentBackground(.hidden)
                                .padding(BTSpacing.md)
                                .frame(minHeight: 80)
                                .background(Color.btSurface)
                                .cornerRadius(BTRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: BTRadius.md)
                                        .stroke(Color.btLine, lineWidth: 1)
                                )

                            HStack {
                                if freeText.count < freeTextMin && !freeText.isEmpty {
                                    Text("\(freeTextMin - freeText.count) more characters needed")
                                        .font(BTFont.body(size: 11))
                                        .foregroundStyle(Color.btText3)
                                }
                                Spacer()
                                Text("\(freeText.count)/\(freeTextMax)")
                                    .font(BTFont.mono(size: 11))
                                    .foregroundStyle(
                                        freeText.count > freeTextMax
                                            ? Color.btPink : Color.btText3
                                    )
                            }
                        }
                    }

                    // Error
                    if let error {
                        Text(error)
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btPink)
                    }

                    // Report Post button
                    Button {
                        submitReport()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color.btText)
                            }
                            Text("Report Post")
                                .font(BTFont.bodySemibold(size: 16))
                        }
                        .foregroundStyle(canSubmit ? Color.btText : Color.btText3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BTSpacing.lg)
                        .background(canSubmit ? Color.btPink : Color.btMuted)
                        .cornerRadius(BTRadius.md)
                    }
                    .disabled(!canSubmit)
                }
                .padding(.horizontal, BTSpacing.xxl)
            }
            .background(Color.btBg.ignoresSafeArea())
            .navigationTitle("Report")
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

    // MARK: - Reason Row

    private func reasonRow(_ reason: ReportReason) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedReason = reason
            }
        } label: {
            HStack(spacing: BTSpacing.md) {
                // Radio button
                Circle()
                    .stroke(
                        selectedReason == reason ? Color.btPink : Color.btLine,
                        lineWidth: 1.5
                    )
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(selectedReason == reason ? Color.btPink : Color.clear)
                            .frame(width: 10, height: 10)
                    )

                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    Text(reason.label)
                        .font(BTFont.bodyMedium(size: 15))
                        .foregroundStyle(Color.btText)
                    Text(reason.desc)
                        .font(BTFont.body(size: 12))
                        .foregroundStyle(Color.btText3)
                }

                Spacer()
            }
            .padding(BTSpacing.md)
            .background(
                selectedReason == reason
                    ? Color.btPink.opacity(0.08) : Color.btSurface
            )
            .cornerRadius(BTRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(
                        selectedReason == reason ? Color.btPink.opacity(0.3) : Color.btLine,
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Submit

    private func submitReport() {
        guard let reason = selectedReason,
              let userId = appState.currentUser?.id
        else { return }

        isSubmitting = true
        let postService = PostService()

        Task {
            do {
                try await postService.report(
                    postId: postId,
                    reporterId: userId,
                    reason: reason.rawValue,
                    freeText: reason == .other ? freeText : nil
                )
                dismiss()
            } catch {
                self.error = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

#Preview {
    ReportModalView(postId: UUID())
        .environment(AppState())
        .preferredColorScheme(.dark)
}
