import Foundation

public struct BaseballLiveKREnvironment: Sendable, Equatable {
    public static let defaultBaseURL = URL(string: "http://127.0.0.1:17361")!
    public static let stagingBaseURL = URL(string: "http://140.245.66.62:17361")!
    public static let productionBaseURL = URL(string: "http://140.245.66.62:17361")!
    public static let defaultAPIPathPrefix = "/v1"
    public static let defaultPollingInterval: Duration = .seconds(15)
    public static let backendBaseURLDefaultsKey = "kbo-live.backend-base-url"

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
