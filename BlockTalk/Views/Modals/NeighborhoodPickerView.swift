import SwiftUI

/// Faithful port of the Expo NeighborhoodPickerScreen: custom search, sticky
/// borough headers, tap-to-select (keyboard drops), bottom confirm CTA.
struct NeighborhoodPickerView: View {
    var currentValue: Neighborhood?
    var title: String = "Home Neighborhood"
    /// Label for the confirm CTA given the picked name (default "MOVE TO X")
    var confirmCta: ((String) -> String)? = nil
    var onConfirm: (Neighborhood) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var picked = ""
    @State private var neighborhoods: [Neighborhood] = []
    @FocusState private var searchFocused: Bool

    private let boroughOrder = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]

    private var sections: [(borough: String, items: [Neighborhood])] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return boroughOrder.compactMap { b in
            let items = neighborhoods.filter {
                $0.borough == b && (q.isEmpty || "\($0.name) \($0.shortCode)".lowercased().contains(q))
            }
            return items.isEmpty ? nil : (borough: b, items: items)
        }
    }

    private var dirty: Bool { picked != (currentValue?.name ?? "") }
    private var canConfirm: Bool { dirty && !picked.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            list
        }
        .background(Color.btBg.ignoresSafeArea())
        .overlay(alignment: .bottom) { confirmBar }
        .onAppear {
            if neighborhoods.isEmpty {
                neighborhoods = NeighborhoodDirectory.all.map {
                    Neighborhood(id: UUID(), name: $0.name, shortCode: $0.shortCode, borough: $0.borough)
                }
            }
            if picked.isEmpty { picked = currentValue?.name ?? "" }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: BTSpacing.xs) {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.btText2)
                    Text(title)
                        .font(BTFont.display(size: 20))
                        .foregroundStyle(Color.btText)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.btBg)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.btLine).frame(height: 1) }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: BTSpacing.sm) {
            Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(Color.btText3)
            TextField("Search neighborhoods", text: $query)
                .font(BTFont.body(size: 13))
                .foregroundStyle(Color.btText)
                .focused($searchFocused)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark").font(.system(size: 12)).foregroundStyle(Color.btText3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 14)
        // Top 12; bottom 4 + the first header's 8 top = 12, so the space
        // above and below the field is identical.
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                if sections.isEmpty {
                    Text("No neighborhoods match \"\(query)\".")
                        .font(BTFont.body(size: 13))
                        .foregroundStyle(Color.btText3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(36)
                } else {
                    ForEach(sections, id: \.borough) { section in
                        Section {
                            ForEach(section.items) { n in
                                row(n)
                                Rectangle().fill(Color.btLine).frame(height: 1)
                            }
                        } header: {
                            Text(section.borough.uppercased())
                                .font(BTFont.bodyBold(size: 15))
                                .tracking(1.0)
                                .foregroundStyle(Color.btLime)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 18)
                                // Uniform padding so every borough sits at the
                                // same height when it pins to the top on scroll.
                                .padding(.top, 8)
                                .padding(.bottom, 8)
                                .background(Color.btBg)
                        }
                    }
                }
            }
            // Clear the floating confirm bar at the bottom
            .padding(.bottom, 96)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func row(_ n: Neighborhood) -> some View {
        let isPicked = n.name == picked
        let isCurrent = n.name == currentValue?.name
        return Button {
            searchFocused = false       // drop the keyboard
            picked = n.name             // select (confirm via the bottom bar)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(n.name).font(BTFont.bodyMedium(size: 14)).foregroundStyle(Color.btText)
                    Text(isCurrent ? "\(n.shortCode)  ·  CURRENT" : n.shortCode)
                        .font(BTFont.mono(size: 10)).tracking(0.4)
                        .foregroundStyle(Color.btText3)
                }
                Spacer()
                if isPicked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.btLime)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(isPicked ? Color.btLime.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm bar

    private var confirmBar: some View {
        Button {
            if canConfirm, let n = neighborhoods.first(where: { $0.name == picked }) {
                onConfirm(n)
                dismiss()
            }
        } label: {
            Text(confirmLabel)
                .font(BTFont.bodyBold(size: 12))
                .tracking(1.2)
                .foregroundStyle(canConfirm ? Color.btOnAccent : Color.btText3)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(canConfirm ? Color.btLime : Color.btSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!canConfirm)
        .padding(.horizontal, 14)
        // Mirrors the Expo bar exactly (top 10, bottom 26). The bar reaches
        // the physical screen bottom (ignoresSafeArea), so the home-indicator
        // area lives inside that 26 rather than being added below it.
        .padding(.top, 10)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity)
        .background(Color.btBg)
        .overlay(alignment: .top) { Rectangle().fill(Color.btLine).frame(height: 1) }
        .ignoresSafeArea(edges: .bottom)
    }

    private var confirmLabel: String {
        if !dirty { return "NO CHANGE" }
        if let cta = confirmCta { return cta(picked) }
        return "MOVE TO \(picked.uppercased())"
    }
}

#Preview {
    NeighborhoodPickerView(currentValue: .les) { n in print("picked \(n.name)") }
        .preferredColorScheme(.dark)
}
