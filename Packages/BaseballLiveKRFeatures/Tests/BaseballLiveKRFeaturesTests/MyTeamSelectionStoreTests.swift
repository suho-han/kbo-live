import Foundation
import Testing
@testable import BaseballLiveKRFeatures

struct MyTeamSelectionStoreTests {
    @Test func oldOnlySelectedTeamIDMigratesToNewDefaultsKey() {
        let defaults = makeDefaults()
        defaults.set("LG", forKey: UserDefaultsMyTeamSelectionStore.legacySelectedTeamIDKey)
        let store = UserDefaultsMyTeamSelectionStore(defaults: defaults)

        #expect(store.loadSelectedTeamID() == "LG")
        #expect(defaults.string(forKey: UserDefaultsMyTeamSelectionStore.selectedTeamIDKey) == "LG")
        #expect(defaults.string(forKey: UserDefaultsMyTeamSelectionStore.legacySelectedTeamIDKey) == nil)
    }

    @Test func newOnlySelectedTeamIDIsUsed() {
        let defaults = makeDefaults()
        defaults.set("KT", forKey: UserDefaultsMyTeamSelectionStore.selectedTeamIDKey)
        let store = UserDefaultsMyTeamSelectionStore(defaults: defaults)

        #expect(store.loadSelectedTeamID() == "KT")
    }

    @Test func bothPresentSelectedTeamIDKeepsNewValue() {
        let defaults = makeDefaults()
        defaults.set("SS", forKey: UserDefaultsMyTeamSelectionStore.selectedTeamIDKey)
        defaults.set("HH", forKey: UserDefaultsMyTeamSelectionStore.legacySelectedTeamIDKey)
        let store = UserDefaultsMyTeamSelectionStore(defaults: defaults)

        #expect(store.loadSelectedTeamID() == "SS")
        #expect(defaults.string(forKey: UserDefaultsMyTeamSelectionStore.legacySelectedTeamIDKey) == "HH")
    }

    @Test func saveSelectedTeamIDWritesOnlyNewDefaultsKey() {
        let defaults = makeDefaults()
        let store = UserDefaultsMyTeamSelectionStore(defaults: defaults)

        store.saveSelectedTeamID("NC")

        #expect(defaults.string(forKey: UserDefaultsMyTeamSelectionStore.selectedTeamIDKey) == "NC")
        #expect(defaults.string(forKey: UserDefaultsMyTeamSelectionStore.legacySelectedTeamIDKey) == nil)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "kr.suhohan.baseballlivekr.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
