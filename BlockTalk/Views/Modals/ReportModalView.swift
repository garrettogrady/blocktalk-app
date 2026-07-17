import SwiftUI

struct ReportModalView: View {
    let postId: UUID
    /// "post" or "reply" — used in the header copy (matches the RN modal).
    var targetLabel: String = "post"
    /// Called on successful submit with the reason's short string, so the
    /// presenting card can flash the "reported for {short} · we'll review" toast.
    var onReported: ((String) -> Void)?

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ReportReason?
    @State private var freeText = ""
    @State private var isSubmitting = false
    @State private var error: String?
    @FocusState private var freeTextFocused: Bool

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
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xxl) {
                    VStack(alignment: .leading, spacing: BTSpacing.sm) {
                        Text("Why are you reporting this \(targetLabel)?")
                            .font(BTFont.display(size: 22))
                            .foregroundStyle(Color.btText)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Only report content that is hateful, racist, or personally identifies someone.")
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btText2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                                .focused($freeTextFocused)
                                .padding(BTSpacing.md)
                                .frame(minHeight: 110)
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
                        .id("freetext")
                    }

                    // Error
                    if let error {
                        Text(error)
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btPink)
                    }
                }
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.bottom, BTSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: freeTextFocused) { _, focused in
                if focused {
                    withAnimation { proxy.scrollTo("freetext", anchor: .bottom) }
                }
            }
            .onChange(of: selectedReason) { _, reason in
                if reason == .other {
                    // Give the editor a beat to appear, then reveal + focus it.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo("freetext", anchor: .bottom) }
                        freeTextFocused = true
                    }
                }
            }
            }
            .background(Color.btBg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                // Report CTA pinned above the keyboard so it's never buried.
                Button {
                    submitReport()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(Color.btText)
                        }
                        Text("Report \(targetLabel.capitalized)")
                            .font(BTFont.bodySemibold(size: 16))
                    }
                    .foregroundStyle(canSubmit ? Color.btText : Color.btText3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.lg)
                    .background(canSubmit ? Color.btPink : Color.btMuted)
                    .cornerRadius(BTRadius.md)
                }
                .disabled(!canSubmit)
                .padding(.horizontal, BTSpacing.xxl)
                .padding(.vertical, BTSpacing.md)
                .frame(maxWidth: .infinity)
                .background(Color.btBg.ignoresSafeArea(.container, edges: .bottom))
            }
            .navigationTitle("Report \(targetLabel.capitalized)")
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
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(reason.desc)
                        .font(BTFont.body(size: 12))
                        .foregroundStyle(Color.btText3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        guard let reason = selectedReason else { return }
        // Local mock: no backend write (Supabase RLS blocks anonymous inserts).
        // The moderation store handles the hide/tombstone; this just confirms.
        onReported?(reason.short)
        dismiss()
    }
}

#Preview {
    ReportModalView(postId: UUID())
        .environment(AppState())
        .preferredColorScheme(.dark)
}
