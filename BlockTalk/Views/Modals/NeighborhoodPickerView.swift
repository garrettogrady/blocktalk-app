import SwiftUI

struct NeighborhoodPickerView: View {
    var currentValue: Neighborhood?
    var onConfirm: (Neighborhood) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedNeighborhood: Neighborhood?
    @State private var neighborhoods: [Neighborhood] = []
    @State private var isLoading = true

    private var grouped: [(borough: String, neighborhoods: [Neighborhood])] {
        let boroughs = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
        let filtered: [Neighborhood]
        if searchText.isEmpty {
            filtered = neighborhoods
        } else {
            let query = searchText.lowercased()
            filtered = neighborhoods.filter {
                $0.name.lowercased().contains(query) ||
                    $0.shortCode.lowercased().contains(query)
            }
        }

        return boroughs.compactMap { borough in
            let entries = filtered.filter { $0.borough == borough }
            guard !entries.isEmpty else { return nil }
            return (borough: borough, neighborhoods: entries)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Color.btText3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.btBg)
                } else {
                    List {
                        ForEach(grouped, id: \.borough) { group in
                            Section {
                                ForEach(group.neighborhoods) { neighborhood in
                                    Button {
                                        selectedNeighborhood = neighborhood
                                    } label: {
                                        HStack(spacing: BTSpacing.md) {
                                            Text(neighborhood.shortCode)
                                                .font(BTFont.monoBold(size: 11))
                                                .foregroundStyle(Color.btLime)
                                                .frame(width: 80, alignment: .leading)

                                            Text(neighborhood.name)
                                                .font(BTFont.bodyMedium(size: 15))
                                                .foregroundStyle(Color.btText)

                                            Spacer()

                                            if selectedNeighborhood?.id == neighborhood.id ||
                                                (selectedNeighborhood == nil && currentValue?.id == neighborhood.id) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(Color.btLime)
                                            }
                                        }
                                    }
                                    .listRowBackground(Color.btSurface)
                                }
                            } header: {
                                Text(group.borough.uppercased())
                                    .font(BTFont.monoBold(size: 12))
                                    .foregroundStyle(Color.btText3)
                            }
                            .id(group.borough)
                        }
                    }
                    .listStyle(.plain)
                    .listRowSeparatorTint(Color.btLine)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .searchable(text: $searchText, prompt: "Search neighborhoods...")
            .background(Color.btBg)
            .navigationTitle("Choose Neighborhood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        if let selected = selectedNeighborhood {
                            onConfirm(selected)
                        }
                        dismiss()
                    }
                    .font(BTFont.bodySemibold(size: 16))
                    .foregroundStyle(selectedNeighborhood != nil ? Color.btLime : Color.btMuted)
                    .disabled(selectedNeighborhood == nil && currentValue == nil)
                }
            }
            .task {
                await loadNeighborhoods()
            }
        }
    }

    private func loadNeighborhoods() async {
        do {
            let service = NeighborhoodService()
            neighborhoods = try await service.fetchAll()
        } catch {
            print("Failed to load neighborhoods: \(error)")
            // Fall back to local directory with random UUIDs as last resort
            neighborhoods = NeighborhoodDirectory.all.map {
                Neighborhood(id: UUID(), name: $0.name, shortCode: $0.shortCode, borough: $0.borough)
            }
        }
        isLoading = false
    }
}

#Preview {
    NeighborhoodPickerView(currentValue: nil) { neighborhood in
        print("Selected: \(neighborhood.name)")
    }
    .preferredColorScheme(.dark)
}
