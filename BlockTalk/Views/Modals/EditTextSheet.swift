import SwiftUI

/// Edit the body text of your own post or reply. Same character limit and the
/// same language gate as composing it in the first place; only the text changes
/// (never the photo, never the pin).
struct EditTextSheet: View {
    let title: String
    let limit: Int
    let original: String
    /// Returns an error message to show, or nil on success.
    let onSave: (String) async -> String?

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var isSaving = false
    @State private var error: String?
    @FocusState private var focused: Bool

    init(title: String, limit: Int, original: String, onSave: @escaping (String) async -> String?) {
        self.title = title
        self.limit = limit
        self.original = original
        self.onSave = onSave
        _text = State(initialValue: original)
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hateSpeech: Bool { LanguageCheck.containsHateSpeech(text) }
    private var overLimit: Bool { text.count > limit }
    private var canSave: Bool {
        !trimmed.isEmpty && trimmed != original && !overLimit && !hateSpeech && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.md) {
                    TextEditor(text: $text)
                        .font(BTFont.body(size: 15))
                        .foregroundStyle(Color.btText)
                        .scrollContentBackground(.hidden)
                        .focused($focused)
                        .padding(BTSpacing.md)
                        .frame(minHeight: 160)
                        .background(Color.btSurface)
                        .cornerRadius(BTRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.md)
                                .stroke(hateSpeech || overLimit ? Color.btPink : Color.btLine, lineWidth: 1)
                        )

                    HStack {
                        if hateSpeech {
                            HStack(spacing: BTSpacing.xs) {
                                Image(systemName: "exclamationmark.octagon")
                                    .font(.system(size: 12))
                                Text("Watch your language. BlockTalk doesn't allow hate speech.")
                                    .font(BTFont.bodySemibold(size: 12))
                            }
                            .foregroundStyle(Color.btPink)
                        }
                        Spacer()
                        Text("\(text.count.formatted()) / \(limit.formatted())")
                            .font(BTFont.mono(size: 11))
                            .foregroundStyle(overLimit ? Color.btPink : Color.btText3)
                    }

                    if let error {
                        Text(error)
                            .font(BTFont.body(size: 13))
                            .foregroundStyle(Color.btPink)
                    }
                }
                .padding(BTSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.btBg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(Color.btLime)
                        } else {
                            Text("Save").font(BTFont.bodySemibold(size: 15))
                        }
                    }
                    .foregroundStyle(canSave ? Color.btLime : Color.btText3)
                    .disabled(!canSave)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        if let message = await onSave(trimmed) {
            error = message
        } else {
            dismiss()
        }
    }
}

#Preview {
    EditTextSheet(title: "Edit post", limit: 1500,
                  original: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter. no regrets.") { _ in nil }
        .preferredColorScheme(.dark)
}
