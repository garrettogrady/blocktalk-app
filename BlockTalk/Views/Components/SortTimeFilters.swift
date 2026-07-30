import SwiftUI

/// Single "sort by" control for a post list — one filter, four orderings.
/// (Collapsed from the old two-filter Sort + Time combo: with both, the priority
/// between them was ambiguous. Time-windowing can return later Reddit-style, as a
/// sub-option under a sort — never as a co-equal second dropdown.)
struct SortFilter: View {
    @Binding var sort: PostSort

    @State private var showPanel = false
    @State private var pendingSort: PostSort?

    var body: some View {
        VStack(spacing: BTSpacing.sm) {
            // Filter button row
            HStack(spacing: BTSpacing.md) {
                filterButton(title: sort.rawValue, isActive: showPanel) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPanel.toggle()
                        pendingSort = sort
                    }
                }
                Spacer()
            }

            // Sort panel
            if showPanel {
                filterPanel(
                    options: PostSort.allCases.map { ($0.rawValue, $0) },
                    selected: pendingSort ?? sort,
                    onSelect: { pendingSort = $0 },
                    onApply: {
                        if let pending = pendingSort { sort = pending }
                        withAnimation { showPanel = false }
                    }
                )
            }
        }
    }

    // MARK: - Filter Button

    private func filterButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BTSpacing.xs) {
                Text(title)
                    .font(BTFont.body(size: 13))
                Image(systemName: isActive ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundStyle(isActive ? Color.btLime : Color.btText2)
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, BTSpacing.sm)
            .background(isActive ? Color.btLime.opacity(0.12) : Color.btSurface)
            .cornerRadius(BTRadius.full)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.full)
                    .stroke(isActive ? Color.btLime.opacity(0.3) : Color.btLine, lineWidth: 1)
            )
        }
    }

    // MARK: - Filter Panel

    private func filterPanel<T: Equatable>(
        options: [(String, T)],
        selected: T,
        onSelect: @escaping (T) -> Void,
        onApply: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    onSelect(option.1)
                } label: {
                    HStack {
                        // Radio
                        Circle()
                            .stroke(
                                selected == option.1 ? Color.btLime : Color.btLine,
                                lineWidth: 1.5
                            )
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .fill(selected == option.1 ? Color.btLime : Color.clear)
                                    .frame(width: 8, height: 8)
                            )

                        Text(option.0)
                            .font(BTFont.bodyMedium(size: 14))
                            .foregroundStyle(Color.btText)

                        Spacer()
                    }
                    .padding(.vertical, BTSpacing.xs)
                }
            }

            Button(action: onApply) {
                Text("Apply")
                    .font(BTFont.bodySemibold(size: 14))
                    .foregroundStyle(Color.btBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.sm)
                    .background(Color.btLime)
                    .cornerRadius(BTRadius.sm)
            }
            .padding(.top, BTSpacing.xs)
        }
        .padding(BTSpacing.lg)
        .background(Color.btSurface)
        .cornerRadius(BTRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(Color.btLine, lineWidth: 1)
        )
        // Expand cleanly out of the button (scale from top) — not a drop-in slide
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        SortFilter(sort: .constant(.newest))
            .padding()
    }
}
