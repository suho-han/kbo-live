import Testing
@testable import BaseballLiveKRCore

struct RuntimeStringSettingMigrationTests {
    @Test func oldOnlyValueIsReturnedPersistedToNewKeyAndRemovedFromLegacyKey() {
        let store = MockRuntimeStringSettingStore(values: ["old": "legacy-value"])

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "legacy-value")
        #expect(store.values["new"] == "legacy-value")
        #expect(store.values["old"] == nil)
    }

    @Test func newOnlyValueWinsWithoutTouchingLegacyKey() {
        let store = MockRuntimeStringSettingStore(values: ["new": "new-value"])

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "new-value")
        #expect(store.values["new"] == "new-value")
        #expect(store.values["old"] == nil)
    }

    @Test func bothPresentKeepsNewValue() {
        let store = MockRuntimeStringSettingStore(values: [
            "new": "new-value",
            "old": "legacy-value"
        ])

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "new-value")
        #expect(store.values["new"] == "new-value")
        #expect(store.values["old"] == "legacy-value")
    }

    @Test func oldInaccessibleBehavesLikeMissingValue() {
        let store = MockRuntimeStringSettingStore(
            values: ["old": "legacy-value"],
            unreadableKeys: ["old"]
        )

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == nil)
        #expect(store.values["new"] == nil)
        #expect(store.values["old"] == "legacy-value")
    }

    @Test func unwritableDestinationStillReturnsReadableLegacyValue() {
        let store = MockRuntimeStringSettingStore(
            values: ["old": "legacy-value"],
            unwritableKeys: ["new"]
        )

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "legacy-value")
        #expect(store.values["new"] == nil)
        #expect(store.values["old"] == "legacy-value")
    }

    @Test func environmentUsesNewValueBeforeLegacyValue() {
        let result = RuntimeStringSettingMigration.resolveEnvironmentValue(
            newName: "BASEBALL_LIVE_KR_BASE_URL",
            legacyName: "KBO_LIVE_BASE_URL",
            environment: [
                "BASEBALL_LIVE_KR_BASE_URL": "https://api.suhohan.kr",
                "KBO_LIVE_BASE_URL": "http://127.0.0.1:17361"
            ],
            isValid: { $0.hasPrefix("https://") || $0.hasPrefix("http://") }
        )

        #expect(result.value == "https://api.suhohan.kr")
    }

    @Test func malformedNewEnvironmentFallsBackToValidLegacyValue() {
        let result = RuntimeStringSettingMigration.resolveEnvironmentValue(
            newName: "BASEBALL_LIVE_KR_BASE_URL",
            legacyName: "KBO_LIVE_BASE_URL",
            environment: [
                "BASEBALL_LIVE_KR_BASE_URL": "not a url",
                "KBO_LIVE_BASE_URL": "http://127.0.0.1:17361"
            ],
            isValid: { $0.hasPrefix("https://") || $0.hasPrefix("http://") }
        )

        #expect(result.value == "http://127.0.0.1:17361")
    }
}

private final class MockRuntimeStringSettingStore: RuntimeStringSettingStore {
    var values: [String: String]
    private let unreadableKeys: Set<String>
    private let unwritableKeys: Set<String>

    init(
        values: [String: String],
        unreadableKeys: Set<String> = [],
        unwritableKeys: Set<String> = []
    ) {
        self.values = values
        self.unreadableKeys = unreadableKeys
        self.unwritableKeys = unwritableKeys
    }

    func string(forKey key: String) -> String? {
        unreadableKeys.contains(key) ? nil : values[key]
    }

    func persistString(_ value: String, forKey key: String) -> Bool {
        guard unwritableKeys.contains(key) == false else {
            return false
        }

        values[key] = value
        return true
    }

    func clearString(forKey key: String) -> Bool {
        values[key] = nil
        return true
    }
}
