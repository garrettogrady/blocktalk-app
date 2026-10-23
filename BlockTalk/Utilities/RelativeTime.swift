import Foundation

enum RelativeTime {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let dateWithYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    /// "now", "4m", "2h", "3d", or "Oct 15" / "Oct 15, 2025" after 30 days.
    static func short(since date: Date, now: Date = Date()) -> String {
        let minutes = Int(now.timeIntervalSince(date) / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        if days <= 30 { return "\(days)d" }
        let cal = Calendar.current
        if cal.component(.year, from: date) == cal.component(.year, from: now) {
            return dateFormatter.string(from: date)
        }
        return dateWithYearFormatter.string(from: date)
    }

    /// "now", "4m ago", "2h ago", "3d ago", or "Oct 15" after 30 days.
    static func long(since date: Date, now: Date = Date()) -> String {
        let s = short(since: date, now: now)
        if s == "now" || s.contains(" ") { return s }
        return s + " ago"
    }
}
