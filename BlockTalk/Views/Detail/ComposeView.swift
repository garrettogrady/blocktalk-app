import PhotosUI
import SwiftUI
import UIKit

struct ComposeView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ComposeViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showAttachDialog = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pinCleared = false
    @FocusState private var textFocused: Bool

    /// Pin can be toggled off locally (the ≡ footer button) without closing
    private var effectivePin: CLLocationCoordinate2D? { pinCleared ? nil : pinDropLocation }
    /// Daily-prompt / NYC-wide compose locks its scope — no feed↔pin toggle
    private var canToggleMode: Bool { !nycWide }

    /// The neighborhood this post will be submitted to
    var postingNeighborhood: Neighborhood?
    /// If set, creates a pin at this location before posting
    var pinDropLocation: CLLocationCoordinate2D?
    /// NYC-wide daily-prompt compose (from the Daily Prompt Feed)
    var nycWide: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        // Scope row
                        scopeRow

                        // Image preview — ABOVE the input, per the mock
                        if let image = viewModel.selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(BTRadius.md)

                                Button {
                                    viewModel.selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.btText)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color.black.opacity(0.7)))
                                }
                                .buttonStyle(.plain)
                                .padding(BTSpacing.sm)
                            }
                        }

                        // Text editor — text flips pink on a hate-speech hit
                        TextEditor(text: $viewModel.text)
                            .font(BTFont.body(size: 16))
                            .foregroundStyle(viewModel.hateSpeechDetected ? Color.btPink : Color.btText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                            .focused($textFocused)
                            .overlay(alignment: .topLeading) {
                                if viewModel.text.isEmpty {
                                    Text(nycWide ? "Answer the prompt…" : "what's on your block?")
                                        .font(BTFont.body(size: 16))
                                        .foregroundStyle(Color.btText3)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }

                        // Hate-speech warning
                        if viewModel.hateSpeechDetected {
                            HStack(alignment: .top, spacing: BTSpacing.sm) {
                                Image(systemName: "exclamationmark.octagon")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.btPink)
                                Text("Watch your language. BlockTalk doesn't allow hate speech.")
                                    .font(BTFont.bodySemibold(size: 12.5))
                                    .foregroundStyle(Color.btPink)
                            }
                            .padding(BTSpacing.md)
                            .background(Color.btPink.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: BTRadius.md)
                                    .stroke(Color.btPink.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                        }
                    }
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.top, BTSpacing.md)
                }

                Divider().background(Color.btLine)

                bottomBar
            }
            .background(Color.btBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        appState.composeDraft = ""
                        dismiss()
                    }
                    .foregroundStyle(Color.btText2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submitPost() }
                        .font(BTFont.bodySemibold(size: 16))
                        .foregroundStyle(viewModel.canSubmit ? Color.btLime : Color.btMuted)
                        .disabled(!viewModel.canSubmit)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog("Add a photo", isPresented: $showAttachDialog, titleVisibility: .hidden) {
                Button("Take Photo") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) { showCamera = true }
                }
                Button("Choose from Library") { showLibrary = true }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(isPresented: $showLibrary, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                        refocusInput()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    viewModel.selectedImage = image
                    refocusInput()
                }
                .ignoresSafeArea()
            }
            .onAppear {
                // Rehydrate a stashed draft after the compose→map→compose round-trip
                if viewModel.text.isEmpty { viewModel.text = appState.composeDraft }
                textFocused = true
            }
            .onChange(of: viewModel.text) { _, newValue in
                appState.composeDraft = newValue
            }
        }
    }

    // MARK: - Scope Row (regular / NYC-wide / pin)

    private var scopeRow: some View {
        HStack(spacing: BTSpacing.sm) {
            Circle().fill(Color.btLime).frame(width: 6, height: 6)
            scopeLabel
            Spacer(minLength: BTSpacing.sm)
            if let status = statusText {
                Text(status)
                    .font(BTFont.monoBold(size: 9.5))
                    .tracking(0.6)
                    .foregroundStyle(Color.btLime)
            }
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.btSurface)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(Color.btLine, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }

    private var scopeLabel: some View {
        let base = Text("Posting to ").font(BTFont.body(size: 10.5)).foregroundColor(.btText2)
        if let coord = effectivePin {
            let latlng = String(format: "%.4f, %.4f", coord.latitude, coord.longitude)
            return base
                + Text("📍 DROPPED PIN").font(BTFont.bodySemibold(size: 10.5)).foregroundColor(.btText)
                + Text(" · ").font(BTFont.body(size: 10.5)).foregroundColor(.btText2)
                + Text(latlng).font(BTFont.mono(size: 10.5)).foregroundColor(.btText)
        } else if nycWide {
            return base
                + Text("TODAY'S PROMPT").font(BTFont.bodySemibold(size: 10.5)).foregroundColor(.btText)
                + Text(" · NYC-WIDE").font(BTFont.body(size: 10.5)).foregroundColor(.btText2)
        } else {
            return base
                + Text(resolvedNeighborhoodName).font(BTFont.bodySemibold(size: 10.5)).foregroundColor(.btText)
        }
    }

    private var statusText: String? {
        if effectivePin != nil { return nil }
        return nycWide ? "▲ IN NYC" : "▲ IN-RANGE"
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: BTSpacing.md) {
            footerIcon("camera", active: viewModel.selectedImage != nil) { showAttachDialog = true }

            // Feed ↔ pin-drop mode toggle (hidden in daily-prompt / NYC-wide)
            if canToggleMode {
                if effectivePin != nil {
                    // ≡ — clear the pin, back to feed mode (no map round-trip)
                    footerIcon("line.3.horizontal") { pinCleared = true }
                } else {
                    // 📍 — stash draft, open Map in drop mode, reopen with the pin
                    footerIcon("mappin") { switchToPinMode() }
                }
            }

            Spacer()

            // Character counter — always visible
            Text("\(viewModel.characterCount.formatted()) / \(ComposeViewModel.postLimit.formatted())")
                .font(BTFont.monoBold(size: 11))
                .foregroundStyle(counterColor)
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.md)
    }

    private func footerIcon(_ systemName: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(active ? Color.btLime : Color.btText2)
                .frame(width: 32, height: 32)
                .background(active ? Color.btLime.opacity(0.1) : Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(active ? Color.btLime.opacity(0.3) : Color.btLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private var counterColor: Color {
        if viewModel.isOverLimit { return .btPink }
        if viewModel.characterCount >= ComposeViewModel.postWarnAt { return .btWarn }
        return .btText3
    }

    // MARK: - Helpers

    private func refocusInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { textFocused = true }
    }

    private var resolvedPostingNeighborhoodId: UUID? {
        postingNeighborhood?.id
            ?? locationService.currentNeighborhood?.id
            ?? appState.currentUser?.homeNeighborhoodId
    }

    private var resolvedNeighborhoodName: String {
        postingNeighborhood?.name
            ?? locationService.currentNeighborhood?.name
            ?? "your neighborhood"
    }

    // MARK: - Submit

    private func submitPost() {
        guard let userId = appState.currentUser?.id ?? appState.session?.user.id else {
            print("Cannot post: no authenticated user")
            return
        }
        guard let neighborhoodId = resolvedPostingNeighborhoodId else {
            print("Cannot post: no neighborhood resolved")
            return
        }
        Task {
            if let pinLocation = effectivePin {
                let pinService = PinService()
                do {
                    let pin = try await pinService.createPin(
                        userId: userId,
                        coordinate: pinLocation,
                        cornerName: nil,
                        neighborhoodId: neighborhoodId
                    )
                    if await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId, pinId: pin.id) != nil {
                        routeAfterPost()
                    }
                } catch {
                    print("Failed to create pin: \(error)")
                    viewModel.error = error.localizedDescription
                }
            } else {
                if await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId) != nil {
                    routeAfterPost()
                }
            }
        }
    }

    /// Post-submit routing follows the post type: pin → Map, feed → Feed,
    /// NYC-wide prompt answers skip routing.
    private func routeAfterPost() {
        appState.composeDraft = ""
        if effectivePin != nil {
            appState.selectedTab = 1
        } else if !nycWide {
            appState.selectedTab = 0
        }
        dismiss()
    }

    private func switchToPinMode() {
        appState.composeDraft = viewModel.text   // stash the draft
        appState.pendingPinPlacement = true       // Map will auto-enter drop mode
        appState.selectedTab = 1
        dismiss()
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ComposeView()
        .environment(AppState())
        .environment(LocationService())
        .preferredColorScheme(.dark)
}
