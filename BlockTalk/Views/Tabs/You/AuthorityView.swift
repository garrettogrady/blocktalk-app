import SwiftUI

/// The Authority page: current level, progress, pace line, a plain-language
/// note on how aura works, and the full ladder. Pushed onto the You tab's
/// NavigationStack. No aura figures and no thresholds anywhere on it.
struct AuthorityView: View {
    @Environment(AppState.self) private var appState

    /// Aura shown while the summary loads; the RPC result replaces it.
    @State private var aura: Int?
    @State private var dailyRate: Double?

    private var level: AuthorityLevel? { aura.map(Authority.level(for:)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.lg) {
                if let aura, let level {
                    hero(aura: aura, level: level)
                    howAuraWorks
                    Text("Nobody reaches City Slicker X on their own.")
                        .font(BTFont.body(size: 11.5))
                        .foregroundStyle(Color.btText3)
                    ladder(current: level)
                } else {
                    ProgressView()
                        .tint(Color.btText3)
                        .frame(maxWidth: .infinity)
                        .padding(.top, BTSpacing.xxxl)
                }
            }
            .padding(BTSpacing.lg)
        }
        .background(Color.btBg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AUTHORITY")
                    .font(BTFont.monoBold(size: 11))
                    .tracking(2)
                    .foregroundStyle(Color.btText2)
            }
        }
        .task { await load() }
    }

    // MARK: - Hero

    private func hero(aura: Int, level: AuthorityLevel) -> some View {
        let tier = level.tier
        let pace = dailyRate.flatMap { Authority.paceLine(aura: aura, dailyRate: $0) }

        return VStack(alignment: .leading, spacing: BTSpacing.lg) {
            VStack(alignment: .leading, spacing: 7) {
                Text("YOUR LEVEL · \(level.index) OF \(Authority.levelCount)")
                    .font(BTFont.mono(size: 10))
                    .tracking(1.4)
                    .foregroundStyle(Color.btText3)
                Text(level.name)
                    .font(BTFont.display(size: 30))
                    .tracking(-0.6)
                    .foregroundStyle(tier.color)
            }

            VStack(alignment: .leading, spacing: 7) {
                AuthorityProgressBar(progress: Authority.progress(for: aura), tier: tier)
                HStack(alignment: .firstTextBaseline) {
                    if let next = level.next {
                        Text("\(Authority.percent(for: aura))% OF THE WAY")
                            .font(BTFont.monoBold(size: 11))
                            .tracking(0.44)
                            .foregroundStyle(tier.color)
                        Spacer(minLength: BTSpacing.sm)
                        Text("TO \(next.name.uppercased())")
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(Color.btText3)
                    } else {
                        Text("TOP LEVEL")
                            .font(BTFont.monoBold(size: 11))
                            .tracking(0.44)
                            .foregroundStyle(tier.color)
                        Spacer(minLength: BTSpacing.sm)
                        Text("NOTHING ABOVE THIS")
                            .font(BTFont.mono(size: 10))
                            .foregroundStyle(Color.btText3)
                    }
                }
                .lineLimit(1)
            }

            if let pace {
                (Text(pace.lead).foregroundStyle(Color.btText3)
                 + Text(pace.emphasis ?? "").font(BTFont.monoBold(size: 10)).foregroundStyle(Color.btText2))
                    .font(BTFont.mono(size: 10))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 11)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Color.btLine).frame(height: 1)
                    }
            }
        }
        .padding(BTSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btSurface)
        .background(alignment: .topTrailing) {
            Circle()
                .fill(RadialGradient(colors: [tier.color.opacity(0.22), .clear],
                                     center: .center, startRadius: 0, endRadius: 58))
                .frame(width: 170, height: 170)
                .offset(x: 52, y: -52)
                .allowsHitTesting(false)
        }
        .overlay(RoundedRectangle(cornerRadius: BTRadius.lg).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
    }

    // MARK: - How aura works

    /// The principle, never the menu: no list of actions, no order, no weights.
    private var howAuraWorks: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HOW AURA WORKS")
                .font(BTFont.monoBold(size: 9.5))
                .tracking(1.3)
                .foregroundStyle(Color.btText3)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.btSurface2)
            Rectangle().fill(Color.btLine).frame(height: 1)

            VStack(alignment: .leading, spacing: 9) {
                (Text("Aura comes from your block.")
                    .font(BTFont.bodySemibold(size: 12.5))
                    .foregroundStyle(Color.btText)
                 + Text(" You earn it when people reply to and upvote what you post. That's where almost all of it comes from.")
                    .font(BTFont.body(size: 12.5))
                    .foregroundStyle(Color.btText2))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Posting, replying and voting earn a little on their own, up to a daily limit. Posting more won't get you there faster. Posting things people want to answer will.")
                    .font(BTFont.body(size: 12.5))
                    .foregroundStyle(Color.btText2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .background(Color.btSurface)
        .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }

    // MARK: - Ladder

    private func ladder(current: AuthorityLevel) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            ForEach(Array(AuthorityTier.allCases.enumerated()), id: \.offset) { i, tier in
                Text(tier.name.uppercased())
                    .font(BTFont.monoBold(size: 9.5))
                    .tracking(1.5)
                    .foregroundStyle(tier.color)
                    .padding(.top, i == 0 ? 0 : 10)

                ForEach(Authority.allLevels.filter { $0.tier == tier }, id: \.index) { level in
                    ladderRow(level, current: current)
                }
            }
        }
        .padding(.top, BTSpacing.sm)
    }

    private enum RowState { case done, current, locked }

    private func ladderRow(_ level: AuthorityLevel, current: AuthorityLevel) -> some View {
        let tier = level.tier
        let state: RowState = level.index < current.index ? .done
            : level.index == current.index ? .current : .locked

        return HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: BTRadius.sm)
                .fill(markFill(state, tier: tier))
                .frame(width: 22, height: 22)
                .overlay {
                    switch state {
                    case .done:
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(tier.color)
                    case .current:
                        Text(level.roman)
                            .font(BTFont.monoBold(size: 9))
                            .foregroundStyle(Color.btOnAccent)
                    case .locked:
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.btText3)
                    }
                }

            Text(level.name.uppercased())
                .font(BTFont.monoBold(size: 11.5))
                .tracking(0.35)
                .foregroundStyle(state == .current ? tier.color : state == .done ? Color.btText2 : Color.btText3)
                .frame(maxWidth: .infinity, alignment: .leading)

            if state == .current {
                Text("YOU")
                    .font(BTFont.monoBold(size: 8.5))
                    .tracking(0.85)
                    .foregroundStyle(Color.btOnAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tier.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(state == .current ? tier.color.opacity(0.09) : Color.btSurface)
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(state == .current ? tier.color.opacity(0.5) : Color.btLine, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        .opacity(state == .locked ? 0.42 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(level, state: state))
    }

    private func markFill(_ state: RowState, tier: AuthorityTier) -> Color {
        switch state {
        case .done: tier.color.opacity(tier == .transplant ? 0.12 : 0.14)
        case .current: tier.color
        case .locked: Color.btElev
        }
    }

    private func accessibilityLabel(_ level: AuthorityLevel, state: RowState) -> String {
        switch state {
        case .done: "\(level.name), earned"
        case .current: "\(level.name), your level"
        case .locked: "\(level.name), locked"
        }
    }

    // MARK: - Data

    private func load() async {
        guard let userId = appState.currentUser?.id else { return }
        // Render immediately from the cached aura; the RPC refines it and adds the rate.
        if aura == nil { aura = appState.currentUser?.aura }

        struct Summary: Decodable {
            let currentAura: Int
            let dailyRate: Double
            enum CodingKeys: String, CodingKey {
                case currentAura = "current_aura"
                case dailyRate = "daily_rate"
            }
        }
        do {
            let rows: [Summary] = try await supabase.rpc(
                "authority_summary",
                params: ["p_user_id": userId.uuidString]
            ).execute().value
            if let row = rows.first {
                aura = row.currentAura
                dailyRate = row.dailyRate
                appState.currentUser?.aura = row.currentAura
            }
        } catch {
            // Keep the hero from the cached aura; just omit the pace line.
            print("AuthorityView: failed to load summary — \(error)")
        }
        // Opening the page counts as seeing the current level (no banner later).
        if let aura { LevelUpTracker.markSeen(userId: userId, aura: aura) }
    }
}

#Preview {
    NavigationStack {
        AuthorityView()
    }
    .environment(AppState())
    .preferredColorScheme(.dark)
}
