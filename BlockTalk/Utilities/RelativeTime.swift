import Foundation

enum RelativeTime {
    /// "now", "4m", "2h", "3d"
    static func short(since date: Date, now: Date = Date()) -> String {
        let minutes = Int(now.timeIntervalSince(date) / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }

    /// "now", "4m ago", "2h ago", "3d ago". Same thresholds as `short`.
    static func long(since date: Date, now: Date = Date()) -> String {
        let s = short(since: date, now: now)
        return s == "now" ? s : s + " ago"
    }
}
