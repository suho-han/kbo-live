import Foundation

public struct KboLiveEnvironment: Sendable, Equatable {
    public static let defaultBaseURL = URL(string: "http://127.0.0.1:17361")!
    public static let stagingBaseURL = URL(string: "https://staging.suhohan.kr")!
    public static let productionBaseURL = URL(string: "https://api.suhohan.kr")!
    public static let defaultAPIPathPrefix = "/v1"
    public static let defaultPollingInterval: Duration = .seconds(15)
    public static let backendBaseURLDefaultsKey = "baseball-live-kr.backend-base-url"
    public static let legacyBackendBaseURLDefaultsKey = "kbo-live.backend-base-url"
    public static let backendBaseURLEnvironmentName = "BASEBALL_LIVE_KR_BASE_URL"
    public static let legacyBackendBaseURLEnvironmentName = "KBO_LIVE_BASE_URL"
    public static let stagingBaseURLEnvironmentName = "BASEBALL_LIVE_KR_STAGING_BASE_URL"
    public static let legacyStagingBaseURLEnvironmentName = "KBO_LIVE_STAGING_BASE_URL"
    public static let productionBaseURLEnvironmentName = "BASEBALL_LIVE_KR_PRODUCTION_BASE_URL"
    public static let legacyProductionBaseURLEnvironmentName = "KBO_LIVE_PRODUCTION_BASE_URL"

    public let baseURL: URL
    public let apiPathPrefix: String
    public let pollingInterval: Duration

    public init(
        baseURL: URL = Self.defaultBaseURL,
        apiPathPrefix: String = Self.defaultAPIPathPrefix,
        pollingInterval: Duration = Self.defaultPollingInterval
    ) {
        self.baseURL = baseURL
        self.apiPathPrefix = apiPathPrefix
        self.pollingInterval = pollingInterval
    }
}

public protocol RuntimeStringSettingStore {
    func string(forKey key: String) -> String?
    @discardableResult
    func persistString(_ value: String, forKey key: String) -> Bool
    @discardableResult
    func clearString(forKey key: String) -> Bool
}

extension UserDefaults: RuntimeStringSettingStore {
    public func persistString(_ value: String, forKey key: String) -> Bool {
        set(value, forKey: key)
        return true
    }

    public func clearString(forKey key: String) -> Bool {
        removeObject(forKey: key)
        return true
    }
}

public enum RuntimeStringSettingMigration {
    public enum Source: Equatable, Sendable {
        case new
        case legacy
        case missing
    }

    public struct Result: Equatable, Sendable {
        public let value: String?
        public let source: Source
        public let persistedLegacyValue: Bool
        public let removedLegacyValue: Bool
        public let destinationUnavailable: Bool

        public init(
            value: String?,
            source: Source,
            persistedLegacyValue: Bool = false,
            removedLegacyValue: Bool = false,
            destinationUnavailable: Bool = false
        ) {
            self.value = value
            self.source = source
            self.persistedLegacyValue = persistedLegacyValue
            self.removedLegacyValue = removedLegacyValue
            self.destinationUnavailable = destinationUnavailable
        }
    }

    public static func resolve(
        store: RuntimeStringSettingStore,
        newKey: String,
        legacyKey: String
    ) -> Result {
        if let value = store.string(forKey: newKey), value.isEmpty == false {
            return Result(value: value, source: .new)
        }

        guard let legacyValue = store.string(forKey: legacyKey), legacyValue.isEmpty == false else {
            return Result(value: nil, source: .missing)
        }

        let persisted = store.persistString(legacyValue, forKey: newKey)
        let removedLegacy = persisted ? store.clearString(forKey: legacyKey) : false
        return Result(
            value: legacyValue,
            source: .legacy,
            persistedLegacyValue: persisted,
            removedLegacyValue: removedLegacy,
            destinationUnavailable: persisted == false
        )
    }

    public static func resolveEnvironmentValue(
        newName: String,
        legacyName: String,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        isValid: (String) -> Bool = { $0.isEmpty == false }
    ) -> Result {
        if let value = environment[newName], isValid(value) {
            return Result(value: value, source: .new)
        }

        if let legacyValue = environment[legacyName], isValid(legacyValue) {
            return Result(value: legacyValue, source: .legacy)
        }

        return Result(value: nil, source: .missing)
    }
}
