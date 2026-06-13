import Foundation

protocol MyTeamSelectionStore: Sendable {
    func loadSelectedTeamID() -> String?
    func saveSelectedTeamID(_ teamID: String?)
}

struct UserDefaultsMyTeamSelectionStore: MyTeamSelectionStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "kbo-live.selected-team-id") {
        self.defaults = defaults
        self.key = key
    }

    func loadSelectedTeamID() -> String? {
        defaults.string(forKey: key)
    }

    func saveSelectedTeamID(_ teamID: String?) {
        if let teamID, teamID.isEmpty == false {
            defaults.set(teamID, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
