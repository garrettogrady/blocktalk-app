import SwiftUI

/// Tapping "edited" on a post or reply: what it said, what it says now. Two
/// states, never more. The original sits one tap below the thing that replaced
/// it, which is the whole anti-bait-and-switch mechanism.
struct EditHistorySheet: View {
    let original: String
    let current: String
    var originalAt: Date?
    var editedAt: Date?
    var noun = "post"

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.md) {
                    VStack(alignment: .leading, spacing: 0) {
                        header("WHAT IT SAID", date: originalAt)
                        body(original, color: .btText3)
                        Rectangle().fill(Color.btLine).frame(height: 1)
                        header("WHAT IT SAYS NOW", date: editedAt)
                        body(current, color: .btText)
                    }
                    .background(Color.btSurface)
                    .overlay(RoundedRectangle(cornerRadius: BTRadius.md).stroke(Color.btLine, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))

                    Text("Votes and replies on this \(noun) came in before the edit.")
                        .font(BTFont.body(size: 11.5))
                        .foregroundStyle(Color.btText3)
                }
                .padding(BTSpacing.lg)
            }
            .background(Color.btBg)
            .navigationTitle("Edited")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.btText2)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func header(_ label: String, date: Date?) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let date {
                Text(Self.stamp(date))
            }
        }
        .font(BTFont.monoBold(size: 9.5))
        .tracking(1.3)
        .foregroundStyle(Color.btText3)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.btSurface2)
    }

    /// "TODAY · 8:25 AM", "YESTERDAY · 8:47 AM", "SEP 21 · 8:47 AM", or with the
    /// year when it differs. The two versions can be days apart, so time alone
    /// isn't enough.
    static func stamp(_ date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        let day: String
        if cal.isDate(date, inSameDayAs: now) {
            day = "Today"
        } else if let yesterday = cal.date(byAdding: .day, value: -1, to: now), cal.isDate(date, inSameDayAs: yesterday) {
            day = "Yesterday"
        } else if cal.isDate(date, equalTo: now, toGranularity: .year) {
            day = date.formatted(.dateTime.month(.abbreviated).day())
        } else {
            day = date.formatted(.dateTime.month(.abbreviated).day().year())
        }
        return "\(day) · \(time)".uppercased()
    }

    private func body(_ text: String, color: Color) -> some View {
        Text(text)
            .font(BTFont.body(size: 13))
            .foregroundStyle(color)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
    }
}

#Preview {
    EditHistorySheet(
        original: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter. no regrets.",
        current: "the bodega cat on 7th just stole someone's breakfast sandwich right off the counter. no regrets. turns out he does this to everyone, not just me.",
        originalAt: Date().addingTimeInterval(-9000),
        editedAt: Date()
    )
    .preferredColorScheme(.dark)
}
