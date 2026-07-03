import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SearchViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: BTSpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.btText3)

                    TextField("Search posts...", text: $viewModel.query)
                        .font(BTFont.body(size: 15))
                        .foregroundStyle(Color.btText)
                        .focused($searchFocused)
                        .autocorrectionDisabled()
                        .onSubmit {
                            performSearch()
                        }

                    if !viewModel.query.isEmpty {
                        Button {
                            viewModel.query = ""
                            viewModel.results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.btText3)
                        }
                    }
                }
                .padding(BTSpacing.md)
                .background(Color.btSurface)
                .cornerRadius(BTRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.md)
                        .stroke(Color.btLine, lineWidth: 1)
                )
                .padding(.horizontal, BTSpacing.lg)
                .padding(.top, BTSpacing.md)

                // Scope chips + sort toggle
                HStack(spacing: BTSpacing.md) {
                    // Scope chips
                    scopeChip("Neighborhood", scope: .neighborhood)
                    scopeChip("Global", scope: .global)

                    Spacer()

                    // Sort toggle
                    Menu {
                        ForEach(SearchViewModel.SearchSort.allCases, id: \.self) { sort in
                            Button {
                                viewModel.sort = sort
                                performSearch()
                            } label: {
                                HStack {
                                    Text(sort.rawValue)
                                    if viewModel.sort == sort {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: BTSpacing.xs) {
                            Text(viewModel.sort.rawValue)
                                .font(BTFont.body(size: 12))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(Color.btText2)
                        .padding(.horizontal, BTSpacing.md)
                        .padding(.vertical, BTSpacing.sm)
                        .background(Color.btSurface)
                        .cornerRadius(BTRadius.full)
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
                .padding(.top, BTSpacing.md)

                Divider().background(Color.btLine)
                    .padding(.top, BTSpacing.md)

                // Results
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                        .tint(Color.btText3)
                    Spacer()
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    Spacer()
                    VStack(spacing: BTSpacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.btText3)
                        Text("No results found")
                            .font(BTFont.body(size: 15))
                            .foregroundStyle(Color.btText3)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.results) { post in
                                PostCard(post: post)
                                Divider().background(Color.btLine)
                            }
                        }
                    }
                }
            }
            .background(Color.btBg)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
            }
            .onAppear {
                searchFocused = true
            }
        }
    }

    private func scopeChip(_ title: String, scope: SearchViewModel.SearchScope) -> some View {
        Button {
            viewModel.scope = scope
            performSearch()
        } label: {
            Text(title)
                .font(BTFont.bodySemibold(size: 13))
                .foregroundStyle(
                    viewModel.scope == scope ? Color.btBg : Color.btText2
                )
                .padding(.horizontal, BTSpacing.md)
                .padding(.vertical, BTSpacing.sm)
                .background(
                    viewModel.scope == scope ? Color.btLime : Color.btSurface
                )
                .cornerRadius(BTRadius.full)
        }
    }

    private func performSearch() {
        let neighborhoodId = appState.currentUser?.homeNeighborhoodId
        Task {
            await viewModel.search(neighborhoodId: neighborhoodId)
        }
    }
}

#Preview {
    SearchView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
