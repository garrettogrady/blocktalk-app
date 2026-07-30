import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PinStore.self) private var pinStore
    @State private var viewModel = SearchViewModel()
    @FocusState private var searchFocused: Bool

    /// Scope is fixed at entry — Feed header → neighborhood, Discover bar →
    /// global. There is NO in-screen scope toggle (deliberate, §12).
    var scope: SearchViewModel.SearchScope = .neighborhood
    /// The neighborhood for a within-neighborhood search (name + short code).
    var neighborhood: Neighborhood?

    private var hasQuery: Bool {
        !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var placeholder: String {
        scope == .neighborhood ? "Search \(neighborhood?.shortCode ?? "here")" : "Search NYC"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
                scopeRow
                Divider().background(Color.btLine)
                resultsArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.btBg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
        }
        .onAppear {
            viewModel.scope = scope
            searchFocused = true
        }
        .onChange(of: viewModel.query) { _, _ in performSearch() }
        .onChange(of: viewModel.sort) { _, _ in performSearch() }
        // Resolve pins for any street comments in the results (corner + map).
        .onChange(of: viewModel.results.map(\.id)) { _, _ in
            Task { await pinStore.ensureLoaded(for: viewModel.results) }
        }
    }

    // MARK: - Top bar (input + Cancel)

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.btText3)
                TextField(placeholder, text: $viewModel.query)
                    .font(BTFont.body(size: 13))
                    .foregroundStyle(Color.btText)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                if hasQuery {
                    Button {
                        viewModel.query = ""
                        viewModel.results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.btText3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 38)
            .padding(.horizontal, BTSpacing.md)
            .background(Color.btSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.btLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button("Cancel") { dismiss() }
                .font(BTFont.bodyMedium(size: 13))
                .foregroundStyle(Color.btText2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.btLine).frame(height: 1)
        }
    }

    // MARK: - Scope chip + sort toggle

    private var scopeRow: some View {
        HStack(spacing: BTSpacing.sm) {
            HStack(spacing: BTSpacing.xs) {
                Image(systemName: scope == .neighborhood ? "house.fill" : "map.fill")
                    .font(.system(size: 10))
                Text(scope == .neighborhood ? "IN \(neighborhood?.shortCode ?? "AREA")" : "ACROSS NYC")
                    .font(BTFont.monoBold(size: 9.5))
                    .tracking(1.1)
            }
            .foregroundStyle(Color.btText)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, BTSpacing.xs)
            .background(Color.btSurface2)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.btLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))

            Spacer()

            // Same sort control as the feed — one filter, four orderings.
            SortFilter(sort: $viewModel.sort)
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, 10)
        .background(Color.btBg)
    }

    // MARK: - Results / three states

    @ViewBuilder
    private var resultsArea: some View {
        if !hasQuery {
            emptyState(
                icon: "magnifyingglass",
                title: scope == .neighborhood ? "Search \(neighborhood?.name ?? "here")." : "Search every neighborhood.",
                sub: "keyword match · \(viewModel.sort.rawValue.lowercased())"
            )
        } else if viewModel.isSearching {
            Spacer(); ProgressView().tint(Color.btText3); Spacer()
        } else if viewModel.results.isEmpty {
            emptyState(
                icon: nil,
                title: "nothing matches \"\(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines))\"",
                sub: scope == .neighborhood ? "in \(neighborhood?.name ?? "this neighborhood")" : "across NYC"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    HStack {
                        Text("\(viewModel.results.count) \(viewModel.results.count == 1 ? "RESULT" : "RESULTS")")
                            .font(BTFont.monoBold(size: 10))
                            .tracking(1.2)
                            .foregroundStyle(Color.btText2)
                        Spacer()
                    }
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.vertical, 10)
                    .background(Color.btBg)

                    ForEach(viewModel.results) { post in
                        NavigationLink(value: post) {
                            PostCard(post: post)
                        }
                        .buttonStyle(.plain)
                        Divider().background(Color.btLine)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func emptyState(icon: String?, title: String, sub: String) -> some View {
        VStack(spacing: BTSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.btText3)
                    .padding(.bottom, BTSpacing.xs)
            }
            Text(title)
                .font(icon == nil ? BTFont.body(size: 14) : BTFont.display(size: 18))
                .foregroundStyle(Color.btText)
                .multilineTextAlignment(.center)
            Text(sub)
                .font(BTFont.monoBold(size: 11))
                .tracking(0.8)
                .foregroundStyle(Color.btText3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, BTSpacing.xxl)
    }

    private func performSearch() {
        Task { await viewModel.search(neighborhoodId: neighborhood?.id) }
    }
}

#Preview {
    SearchView(scope: .neighborhood, neighborhood: nil)
        .preferredColorScheme(.dark)
}
