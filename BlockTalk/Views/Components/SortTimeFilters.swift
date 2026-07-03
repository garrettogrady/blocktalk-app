import SwiftUI

struct SortTimeFilters: View {
    @Binding var sort: PostSort
    @Binding var timeFilter: TimeFilter

    @State private var showSortPanel = false
    @State private var showTimePanel = false

    @State private var pendingSort: PostSort?
    @State private var pendingTime: TimeFilter?

    var body: some View {
        VStack(spacing: BTSpacing.sm) {
            // Filter buttons row
            HStack(spacing: BTSpacing.md) {
                filterButton(
                    title: sort.rawValue,
                    isActive: showSortPanel
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSortPanel.toggle()
                        showTimePanel = false
                        pendingSort = sort
                    }
                }

                filterButton(
                    title: timeFilter.rawValue,
                    isActive: showTimePanel
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTimePanel.toggle()
                        showSortPanel = false
                        pendingTime = timeFilter
                    }
                }

                Spacer()
            }

            // Sort panel
            if showSortPanel {
                filterPanel(
                    options: PostSort.allCases.map { ($0.rawValue, $0) },
                    selected: pendingSort ?? sort,
                    onSelect: { pendingSort = $0 },
                    onApply: {
                        if let pending = pendingSort { sort = pending }
                        withAnimation { showSortPanel = false }
                    }
                )
            }

            // Time panel
            if showTimePanel {
                filterPanel(
                    options: TimeFilter.allCases.map { ($0.rawValue, $0) },
                    selected: pendingTime ?? timeFilter,
                    onSelect: { pendingTime = $0 },
                    onApply: {
                        if let pending = pendingTime { timeFilter = pending }
                        withAnimation { showTimePanel = false }
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        SortTimeFilters(
            sort: .constant(.newest),
            timeFilter: .constant(.day)
        )
        .padding()
    }
}
