import Foundation

protocol MyTeamSelectionStore: Sendable {
    func loadSelectedTeamID() -> String?
    func saveSelectedTeamID(_ teamID: String?)
}

struct UserDefaultsMyTeamSelectionStore: MyTeamSelectionStore, @unchecked Sendable {
    static let selectedTeamIDKey = "baseball-live-kr.selected-team-id"
    static let legacySelectedTeamIDKey = "kbo-live.selected-team-id"

    private let defaults: UserDefaults
    private let key: String
    private let legacyKey: String

    init(
        defaults: UserDefaults = .standard,
        key: String = Self.selectedTeamIDKey,
        legacyKey: String = Self.legacySelectedTeamIDKey
    ) {
        self.defaults = defaults
        self.key = key
        self.legacyKey = legacyKey
    }

    func loadSelectedTeamID() -> String? {
        if let selectedTeamID = defaults.string(forKey: key), selectedTeamID.isEmpty == false {
            return selectedTeamID
        }

        guard let legacySelectedTeamID = defaults.string(forKey: legacyKey),
              legacySelectedTeamID.isEmpty == false else {
            return nil
        }

        defaults.set(legacySelectedTeamID, forKey: key)
        defaults.removeObject(forKey: legacyKey)
        return legacySelectedTeamID
    }

    func saveSelectedTeamID(_ teamID: String?) {
        if let teamID, teamID.isEmpty == false {
            defaults.set(teamID, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
