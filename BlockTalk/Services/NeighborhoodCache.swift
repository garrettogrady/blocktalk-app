import Foundation

@Observable
final class NeighborhoodCache {
    private(set) var neighborhoods: [Neighborhood] = []
    private var byId: [UUID: Neighborhood] = [:]
    private var byName: [String: Neighborhood] = [:]

    func loadAll() async {
        do {
            let service = NeighborhoodService()
            let fetched = try await service.fetchAll()
            neighborhoods = fetched
            // uniquingKeysWith (NOT uniqueKeysWithValues) — the latter traps/crashes
            // on a duplicate key, and this runs on the launch path. NYC genuinely has
            // repeated neighborhood names across boroughs (e.g. Chelsea), so a future
            // seed could otherwise crash the app on startup. Keep the first match.
            byId = Dictionary(fetched.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            byName = Dictionary(fetched.map { ($0.name.lowercased(), $0) }, uniquingKeysWith: { a, _ in a })
        } catch {
            print("NeighborhoodCache: failed to load — \(error)")
        }
    }

    func neighborhood(id: UUID) -> Neighborhood? {
        byId[id]
    }

    func neighborhood(named name: String) -> Neighborhood? {
        byName[name.lowercased()]
    }
}
