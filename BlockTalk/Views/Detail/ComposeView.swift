import PhotosUI
import SwiftUI

struct ComposeView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ComposeViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var textFocused: Bool

    /// The neighborhood this post will be submitted to
    var postingNeighborhood: Neighborhood?
    /// If set, creates a pin at this location before posting
    var pinDropLocation: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope row
                scopeRow

                Divider().background(Color.btLine)

                // Text editor
                ScrollView {
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        TextEditor(text: $viewModel.text)
                            .font(BTFont.body(size: 16))
                            .foregroundStyle(Color.btText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .focused($textFocused)

                        // Selected image preview
                        if let image = viewModel.selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(BTRadius.md)
                                    .clipped()

                                Button {
                                    viewModel.selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color.btText)
                                        .background(Circle().fill(Color.btBg.opacity(0.6)))
                                }
                                .padding(BTSpacing.sm)
                            }
                        }

                        // Hate speech warning
                        if viewModel.hateSpeechDetected {
                            HStack(spacing: BTSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.btPink)
                                Text("This post may contain hate speech and cannot be submitted.")
                                    .font(BTFont.body(size: 13))
                                    .foregroundStyle(Color.btPink)
                            }
                            .padding(BTSpacing.md)
                            .background(Color.btPink.opacity(0.1))
                            .cornerRadius(BTRadius.md)
                        }
                    }
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.top, BTSpacing.md)
                }

                Divider().background(Color.btLine)

                // Bottom bar
                bottomBar
            }
            .background(Color.btBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.btText2)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        submitPost()
                    }
                    .font(BTFont.bodySemibold(size: 16))
                    .foregroundStyle(viewModel.canSubmit ? Color.btLime : Color.btMuted)
                    .disabled(!viewModel.canSubmit)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                textFocused = true
            }
        }
    }

    // MARK: - Scope Row

    private var scopeRow: some View {
        HStack(spacing: BTSpacing.md) {
            // Neighborhood
            HStack(spacing: BTSpacing.xs) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.btLime)
                Text("Posting to \(resolvedNeighborhoodName)")
                    .font(BTFont.body(size: 13))
                    .foregroundStyle(Color.btText2)
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, BTSpacing.sm)
            .background(Color.btSurface)
            .cornerRadius(BTRadius.full)

            // Status
            HStack(spacing: BTSpacing.xs) {
                Circle()
                    .fill(Color.btLime)
                    .frame(width: 6, height: 6)
                Text("IN-RANGE")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btLime)
            }

            Spacer()
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.md)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: BTSpacing.lg) {
            // Image picker
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.btText2)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                    }
                }
            }

            Spacer()

            // Character counter
            if viewModel.showCounter {
                Text("\(viewModel.characterCount)/\(ComposeViewModel.postLimit)")
                    .font(BTFont.mono(size: 12))
                    .foregroundStyle(
                        viewModel.isOverLimit ? Color.btPink : Color.btWarn
                    )
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.md)
    }

    // MARK: - Helpers

    /// The neighborhood ID to post to
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
            // If this is a pin drop, create the pin first
            if let pinLocation = pinDropLocation {
                let pinService = PinService()
                do {
                    let pin = try await pinService.createPin(
                        userId: userId,
                        coordinate: pinLocation,
                        cornerName: nil,
                        neighborhoodId: neighborhoodId
                    )
                    if let _ = await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId, pinId: pin.id) {
                        dismiss()
                    }
                } catch {
                    print("Failed to create pin: \(error)")
                    viewModel.error = error.localizedDescription
                }
            } else {
                if let _ = await viewModel.submit(userId: userId, neighborhoodId: neighborhoodId) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ComposeView()
        .environment(AppState())
        .environment(LocationService())
        .preferredColorScheme(.dark)
}
