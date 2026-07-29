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
            byId = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            byName = Dictionary(uniqueKeysWithValues: fetched.map { ($0.name.lowercased(), $0) })
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
