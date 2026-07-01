import Foundation

enum FixtureLoader {
    static func loadData(named name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "FixtureLoader", code: 404, userInfo: [NSLocalizedDescriptionKey: "Missing fixture: \(name).json"])
        }

        return try Data(contentsOf: url)
    }
}
