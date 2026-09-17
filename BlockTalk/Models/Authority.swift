import SwiftUI

enum AuthorityTier: CaseIterable, Sendable {
    case transplant
    case blocktalker
    case citySlicker

    var name: String {
        switch self {
        case .transplant: "Transplant"
        case .blocktalker: "Blocktalker"
        case .citySlicker: "City Slicker"
        }
    }

    /// Level indexes (1-based) that belong to this tier.
    var levels: ClosedRange<Int> {
        switch self {
        case .transplant: 1...3
        case .blocktalker: 4...6
        case .citySlicker: 7...16
        }
    }

    var color: Color {
        switch self {
        case .transplant: .btText
        case .blocktalker: .btLime
        case .citySlicker: .btSlicker
        }
    }

    /// Start of the progress-bar gradient.
    var dimColor: Color {
        switch self {
        case .transplant: .btText2
        case .blocktalker: .btLimeDim
        case .citySlicker: .btSlickerDim
        }
    }

    /// Badge fill and stroke strengths, tuned per colour so all three read at equal weight.
    var badgeFillOpacity: Double {
        switch self {
        case .transplant: 0.11
        case .blocktalker: 0.12
        case .citySlicker: 0.15
        }
    }

    var badgeStrokeOpacity: Double {
        switch self {
        case .transplant: 0.26
        case .blocktalker: 0.34
        case .citySlicker: 0.40
        }
    }
}

struct AuthorityLevel: Equatable, Hashable, Sendable {
    /// 1...16
    let index: Int

    var tier: AuthorityTier {
        AuthorityTier.allCases.first { $0.levels.contains(index) } ?? .citySlicker
    }

    /// Position within the tier, 1-based ("VI" in City Slicker VI is 6).
    var rank: Int { index - tier.levels.lowerBound + 1 }
    var roman: String { Authority.roman(rank) }
    var name: String { "\(tier.name) \(roman)" }
    var isMax: Bool { index == Authority.levelCount }
    /// True for Blocktalker I and City Slicker I: the two tier crossings.
    var isTierEntry: Bool { rank == 1 && index > 1 }
    var next: AuthorityLevel? { isMax ? nil : AuthorityLevel(index: index + 1) }
}

enum Authority {
    /// Mirrors authority_thresholds() in Supabase/00023_authority.sql.
    /// SQL is the source of truth; AuthorityTests fails if these drift.
    static let thresholds: [Int] = [0, 50, 150, 400, 900, 1800, 3000, 4400, 6000, 7800, 9800, 12000, 14400, 17000, 19800, 22800]
    static let levelCount = 16

    static let allLevels: [AuthorityLevel] = (1...levelCount).map(AuthorityLevel.init(index:))

    static func level(for aura: Int) -> AuthorityLevel {
        AuthorityLevel(index: thresholds.lastIndex { $0 <= max(aura, 0) }.map { $0 + 1 } ?? 1)
    }

    /// 0...1 progress from the current level's threshold to the next. 1 at the top level.
    static func progress(for aura: Int) -> Double {
        let level = level(for: aura)
        guard !level.isMax else { return 1 }
        let floor = thresholds[level.index - 1]
        let ceiling = thresholds[level.index]
        return Double(max(aura, 0) - floor) / Double(ceiling - floor)
    }

    /// Whole percent, rounded down so a user never sees 100% before they level up.
    static func percent(for aura: Int) -> Int {
        Int((progress(for: aura) * 100).rounded(.down))
    }

    static func levelsRemaining(for aura: Int) -> Int {
        levelCount - level(for: aura).index
    }

    /// The Authority page's closing line. `dailyRate` comes from authority_summary().
    static func paceLine(aura: Int, dailyRate: Double) -> PaceLine {
        let level = level(for: aura)
        guard let next = level.next else {
            return PaceLine(lead: "You're at the top level. There's nothing above this one.", emphasis: nil)
        }
        let neutral = PaceLine(lead: "Keep going and you'll get there.", emphasis: nil)
        guard dailyRate > 0 else { return neutral }

        let remaining = thresholds[next.index - 1] - max(aura, 0)
        let days = Int((Double(remaining) / dailyRate).rounded(.up))
        let lead = "Keep going the way you have been and you'll get there in "

        switch days {
        case ...1:
            return PaceLine(lead: "You'll get there today if you keep this up.", emphasis: nil)
        case 2...13:
            return PaceLine(lead: lead, emphasis: "about \(days) days.")
        case 14...60:
            let weeks = Int((Double(days) / 7).rounded())
            return PaceLine(lead: lead, emphasis: "about \(weeks) weeks.")
        default:
            return neutral
        }
    }

    static func roman(_ n: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        return numerals.indices.contains(n - 1) ? numerals[n - 1] : "\(n)"
    }
}

/// A pace-line sentence split so the estimate can render with emphasis.
struct PaceLine: Equatable {
    let lead: String
    let emphasis: String?
}
