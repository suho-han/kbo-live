import Foundation
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif

struct WidgetGameSnapshotStore {
    static let appGroupIdentifier = "group.com.suhohan.kbo-live"
    static let snapshotKey = "kbo-live.widget.snapshot"
    static let lastUpdatedAtKey = "kbo-live.widget.snapshot-updated-at"

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = WidgetGameSnapshotStore.defaultUserDefaults) {
        self.defaults = defaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    var snapshot: WidgetGameSnapshot? {
        guard let data = defaults.data(forKey: Self.snapshotKey) else {
            return nil
        }

        return try? decoder.decode(WidgetGameSnapshot.self, from: data)
    }

    func save(_ snapshot: WidgetGameSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: Self.snapshotKey)
        defaults.set(Date(), forKey: Self.lastUpdatedAtKey)
    }

    func clear() {
        defaults.removeObject(forKey: Self.snapshotKey)
        defaults.removeObject(forKey: Self.lastUpdatedAtKey)
    }

    static var defaultUserDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
