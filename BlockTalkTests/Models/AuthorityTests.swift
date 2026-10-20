import XCTest
@testable import BlockTalk

final class AuthorityTests: XCTestCase {

    // MARK: - SQL parity (the one real correctness risk)

    /// The threshold table lives in two places: authority_thresholds() in SQL,
    /// because the level-up trigger must detect boundary crossings, and
    /// Authority.thresholds in Swift, because the client computes progress
    /// locally. SQL is the source of truth; this fails if they drift.
    func testThresholdsMatchMigration() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Models
            .deletingLastPathComponent()   // BlockTalkTests
            .deletingLastPathComponent()   // repo root
        let sqlURL = repoRoot.appendingPathComponent("Supabase/00023_authority.sql")
        let sql = try String(contentsOf: sqlURL, encoding: .utf8)

        guard let start = sql.range(of: "AUTHORITY_THRESHOLDS_BEGIN")?.upperBound,
              let end = sql.range(of: "AUTHORITY_THRESHOLDS_END")?.lowerBound else {
            return XCTFail("Threshold markers missing from 00023_authority.sql")
        }
        let segment = sql[start..<end]
        guard let open = segment.range(of: "ARRAY[")?.upperBound,
              let close = segment[open...].firstIndex(of: "]") else {
            return XCTFail("ARRAY[...] not found between threshold markers")
        }
        let parsed = segment[open..<close]
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

        XCTAssertEqual(parsed, Authority.thresholds)
    }

    // MARK: - Thresholds

    func testThresholdShape() {
        XCTAssertEqual(Authority.thresholds.count, 16)
        XCTAssertEqual(Authority.thresholds.first, 0)
        for (a, b) in zip(Authority.thresholds, Authority.thresholds.dropFirst()) {
            XCTAssertLessThan(a, b)
        }
    }

    func testLevelAtEveryBoundary() {
        for (i, threshold) in Authority.thresholds.enumerated() {
            XCTAssertEqual(Authority.level(for: threshold).index, i + 1, "at \(threshold)")
            if threshold > 0 {
                XCTAssertEqual(Authority.level(for: threshold - 1).index, i, "just below \(threshold)")
            }
        }
    }

    func testLevelClampsOutOfRange() {
        XCTAssertEqual(Authority.level(for: -5).index, 1)
        XCTAssertEqual(Authority.level(for: 999_999).index, 16)
    }

    // MARK: - Names and tiers

    func testLevelNames() {
        XCTAssertEqual(AuthorityLevel(index: 1).name, "Transplant I")
        XCTAssertEqual(AuthorityLevel(index: 4).name, "Blocktalker I")
        XCTAssertEqual(AuthorityLevel(index: 6).name, "Blocktalker III")
        XCTAssertEqual(AuthorityLevel(index: 7).name, "City Slicker I")
        XCTAssertEqual(AuthorityLevel(index: 16).name, "City Slicker X")
    }

    func testTierEntryLevels() {
        XCTAssertEqual(Authority.allLevels.filter(\.isTierEntry).map(\.index), [4, 7])
    }

    func testRomanNumerals() {
        XCTAssertEqual(Authority.roman(1), "I")
        XCTAssertEqual(Authority.roman(4), "IV")
        XCTAssertEqual(Authority.roman(9), "IX")
        XCTAssertEqual(Authority.roman(10), "X")
    }

    // MARK: - Progress

    func testProgress() {
        XCTAssertEqual(Authority.progress(for: 50), 0)
        XCTAssertEqual(Authority.progress(for: 100), 0.5)
        XCTAssertEqual(Authority.progress(for: 22_800), 1)
    }

    func testPercentRoundsDown() {
        XCTAssertEqual(Authority.percent(for: 2_999), 99)
    }

    func testLevelsRemaining() {
        XCTAssertEqual(Authority.levelsRemaining(for: 0), 15)
        XCTAssertEqual(Authority.levelsRemaining(for: 22_800), 0)
    }

    // MARK: - Pace line

    func testPaceLineHiddenInTransplant() {
        XCTAssertNil(Authority.paceLine(aura: 0, dailyRate: 10))
        XCTAssertNil(Authority.paceLine(aura: 149, dailyRate: 10))
        XCTAssertNotNil(Authority.paceLine(aura: 400, dailyRate: 10))
    }

    func testPaceLineNeutralWhenRateIsZero() {
        XCTAssertEqual(Authority.paceLine(aura: 400, dailyRate: 0)?.lead, "Keep going and you'll get there.")
    }

    func testPaceLineToday() {
        // 500 to Blocktalker II at 500/day
        XCTAssertEqual(Authority.paceLine(aura: 400, dailyRate: 500)?.lead, "You'll get there today if you keep this up.")
    }

    func testPaceLineDays() {
        // 500 to Blocktalker II at 100/day
        XCTAssertEqual(Authority.paceLine(aura: 400, dailyRate: 100)?.emphasis, "about 5 days.")
    }

    func testPaceLineWeeks() {
        // 1,400 aura to City Slicker II at 1,400/21 per day = 21 days = 3 weeks
        XCTAssertEqual(Authority.paceLine(aura: 3_000, dailyRate: 1_400.0 / 21)?.emphasis, "about 3 weeks.")
    }

    func testPaceLineSuppressedPast60Days() {
        XCTAssertEqual(Authority.paceLine(aura: 400, dailyRate: 500.0 / 61)?.lead, "Keep going and you'll get there.")
    }

    func testPaceLineAtTop() {
        XCTAssertEqual(Authority.paceLine(aura: 22_800, dailyRate: 10)?.lead,
                       "You're at the top level. There's nothing above this one.")
    }

    // MARK: - Notification level parsing

    func testNotificationAuthorityLevel() {
        let note = BTNotification(id: UUID(), userId: UUID(), kind: "authority", title: "x",
                                  preview: nil, meta: "level:7", unread: true, relatedPostId: nil, createdAt: nil)
        XCTAssertEqual(note.authorityLevel?.index, 7)

        let other = BTNotification(id: UUID(), userId: UUID(), kind: "reply", title: "x",
                                   preview: nil, meta: "level:7", unread: true, relatedPostId: nil, createdAt: nil)
        XCTAssertNil(other.authorityLevel)
    }

    // MARK: - RelativeTime

    func testRelativeTimeShort() {
        let now = Date()
        XCTAssertEqual(RelativeTime.short(since: now.addingTimeInterval(-30), now: now), "now")
        XCTAssertEqual(RelativeTime.short(since: now.addingTimeInterval(-240), now: now), "4m")
        XCTAssertEqual(RelativeTime.short(since: now.addingTimeInterval(-7_200), now: now), "2h")
        XCTAssertEqual(RelativeTime.short(since: now.addingTimeInterval(-259_200), now: now), "3d")
    }
}

final class DayOneStoreTests: XCTestCase {
    private let alice = UUID()
    private let bob = UUID()
    private let les = UUID()
    private let fidi = UUID()

    @MainActor
    func testLookupAndPerNeighborhoodCounts() {
        let store = DayOneStore()
        store.apply([
            DayOneSlot(neighborhoodId: les, rank: 1, userId: alice, shortCode: "LES"),
            DayOneSlot(neighborhoodId: fidi, rank: 1, userId: bob, shortCode: "FIDI"),
            DayOneSlot(neighborhoodId: les, rank: 2, userId: UUID(), shortCode: "LES"),
        ])
        XCTAssertEqual(store.rank(for: alice), 1)
        XCTAssertEqual(store.slot(for: bob)?.shortCode, "FIDI")
        XCTAssertNil(store.slot(for: UUID()))
        XCTAssertEqual(store.claimed(in: les), 2)
        XCTAssertEqual(store.remaining(in: les), 48)
        XCTAssertEqual(store.remaining(in: fidi), 49)
        XCTAssertEqual(store.remaining(in: UUID()), DayOneSlot.capacity, "an untouched neighborhood has all fifty")
        XCTAssertTrue(store.loaded)
    }

    @MainActor
    func testDeletedAccountKeepsItsSlot() {
        let store = DayOneStore()
        store.apply([DayOneSlot(neighborhoodId: les, rank: 1, userId: nil),
                     DayOneSlot(neighborhoodId: les, rank: 2, userId: alice)])
        XCTAssertEqual(store.remaining(in: les), 48, "a vacated slot is not refilled")
        XCTAssertEqual(store.rank(for: alice), 2)
    }

    func testDecodesSupabaseShape() throws {
        let json = """
        [{"neighborhood_id": "\(les.uuidString)", "rank": 1, "user_id": "\(alice.uuidString)",
          "user": {"username": "orchardst"}, "neighborhood": {"short_code": "LES", "name": "Lower East Side"}},
         {"neighborhood_id": "\(fidi.uuidString)", "rank": 2, "user_id": null, "user": null, "neighborhood": null}]
        """.data(using: .utf8)!
        let slots = try JSONDecoder().decode([DayOneSlot].self, from: json)
        XCTAssertEqual(slots[0].neighborhoodId, les)
        XCTAssertEqual(slots[0].rank, 1)
        XCTAssertEqual(slots[0].userId, alice)
        XCTAssertEqual(slots[0].username, "orchardst")
        XCTAssertEqual(slots[0].shortCode, "LES")
        XCTAssertEqual(slots[0].neighborhoodName, "Lower East Side")
        XCTAssertNil(slots[1].userId)
        XCTAssertNil(slots[1].shortCode)
    }

    @MainActor
    func testEmptyStoreShowsNothing() {
        let store = DayOneStore()
        XCTAssertFalse(store.loaded)
        XCTAssertNil(store.slot(for: alice))
        XCTAssertEqual(store.remaining(in: les), DayOneSlot.capacity)
    }
}
