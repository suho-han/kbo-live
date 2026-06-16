import Foundation
#if canImport(KboLiveCore)
import KboLiveCore
#endif

@MainActor
final class BackendSettingsModel: ObservableObject {
    enum BackendPreset: String, CaseIterable, Identifiable {
        case local
        case production

        var id: String { rawValue }

        var title: String {
            switch self {
            case .local:
                return "Local"
            case .production:
                return "Production"
            }
        }

        var description: String {
            switch self {
            case .local:
                return "현재 Mac에서 실행 중인 packaged backend"
            case .production:
                return "운영 backend"
            }
        }
    }

    enum ValidationState: Equatable {
        case idle
        case checking
        case available
        case unavailable(String)
    }

    @Published private(set) var selectedPreset: BackendPreset
    @Published var baseURLText: String
    @Published private(set) var validationState: ValidationState = .idle

    private let defaults: UserDefaults
    private let baseURLKey = KboLiveEnvironment.backendBaseURLDefaultsKey
    private let presetKey = "kbo-live.backend-preset"
    private let productionBaseURLKey = "kbo-live.backend-production-base-url"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedPreset = defaults.string(forKey: presetKey).flatMap(BackendPreset.init(rawValue:)) ?? .production
        let resolvedPreset = Self.resolvedPreset(from: storedPreset, defaults: defaults)
        self.selectedPreset = resolvedPreset
        self.baseURLText = Self.resolvedBaseURLString(defaults: defaults)
    }

    var isEnvironmentOverridden: Bool {
        Self.environmentBaseURLString != nil
    }

    var effectiveBaseURL: URL {
        Self.normalizedURL(from: baseURLText) ?? Self.resolvedBaseURL(defaults: defaults)
    }

    var selectedPresetTitle: String {
        if isEnvironmentOverridden {
            return "Environment"
        }

        return selectedPreset.title
    }

    func makeClient() -> GameFeedClient {
        GameFeedClient.live(baseURL: effectiveBaseURL)
    }

    func hasConfiguredBaseURL(for preset: BackendPreset) -> Bool {
        Self.baseURLString(for: preset, defaults: defaults) != nil
    }

    func baseURLDescription(for preset: BackendPreset) -> String {
        Self.baseURLString(for: preset, defaults: defaults) ?? "URL 미설정"
    }

    func selectPreset(_ preset: BackendPreset) {
        guard isEnvironmentOverridden == false else {
            return
        }

        selectedPreset = preset
        validationState = .idle

        baseURLText = Self.baseURLString(for: preset, defaults: defaults) ?? ""
    }

    func save() -> Bool {
        guard let url = Self.normalizedURL(from: baseURLText) else {
            validationState = .unavailable("URL 형식이 올바르지 않습니다.")
            return false
        }

        baseURLText = url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if isEnvironmentOverridden {
            validationState = .idle
            return true
        }

        defaults.set(baseURLText, forKey: baseURLKey)
        defaults.set(selectedPreset.rawValue, forKey: presetKey)

        switch selectedPreset {
        case .local:
            break
        case .production:
            defaults.set(baseURLText, forKey: productionBaseURLKey)
        }

        validationState = .idle
        return true
    }

    func reset() {
        selectedPreset = .production
        baseURLText = Self.environmentBaseURLString ?? Self.productionBaseURLString
        if isEnvironmentOverridden == false {
            defaults.removeObject(forKey: baseURLKey)
            defaults.removeObject(forKey: presetKey)
        }
        validationState = .idle
    }

    func checkHealth() async {
        guard let baseURL = Self.normalizedURL(from: baseURLText),
              let url = Self.backendURL(
                baseURL: baseURL,
                path: "ready",
                apiPathPrefix: KboLiveEnvironment.defaultAPIPathPrefix
              ) else {
            validationState = .unavailable("URL 형식이 올바르지 않습니다.")
            return
        }

        validationState = .checking

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 2
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode) {
                validationState = .available
            } else {
                validationState = .unavailable("서버가 정상 응답을 반환하지 않았습니다.")
            }
        } catch {
            validationState = .unavailable("백엔드 서버에 연결할 수 없습니다.")
        }
    }

    nonisolated static var defaultBaseURLString: String {
        KboLiveEnvironment.defaultBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    nonisolated static func resolvedBaseURL(defaults: UserDefaults = .standard) -> URL {
        if let url = normalizedURL(from: resolvedBaseURLString(defaults: defaults)) {
            return url
        }

        return KboLiveEnvironment.productionBaseURL
    }

    nonisolated static func backendURL(baseURL: URL, path: String) -> URL? {
        backendURL(
            baseURL: baseURL,
            path: path,
            apiPathPrefix: KboLiveEnvironment.defaultAPIPathPrefix
        )
    }

    nonisolated private static func resolvedBaseURLString(defaults: UserDefaults) -> String {
        if let environmentBaseURLString {
            return environmentBaseURLString
        }

        if let storedBaseURL = defaults.string(forKey: KboLiveEnvironment.backendBaseURLDefaultsKey),
           isLegacyLocalBaseURL(storedBaseURL) == false {
            return storedBaseURL
        }

        let storedPreset = defaults.string(forKey: "kbo-live.backend-preset")
            .flatMap(BackendPreset.init(rawValue:)) ?? .production
        let preset = resolvedPreset(from: storedPreset, defaults: defaults)
        return baseURLString(for: preset, defaults: defaults) ?? productionBaseURLString
    }

    nonisolated private static func resolvedPreset(from storedPreset: BackendPreset, defaults: UserDefaults) -> BackendPreset {
        if let storedBaseURL = defaults.string(forKey: KboLiveEnvironment.backendBaseURLDefaultsKey),
           isLegacyLocalBaseURL(storedBaseURL) {
            return .production
        }

        return baseURLString(for: storedPreset, defaults: defaults) == nil ? .production : storedPreset
    }

    nonisolated private static func baseURLString(for preset: BackendPreset, defaults: UserDefaults) -> String? {
        switch preset {
        case .local:
            return defaultBaseURLString
        case .production:
            return environmentBaseURLString(named: "KBO_LIVE_PRODUCTION_BASE_URL")
                ?? defaults.string(forKey: "kbo-live.backend-production-base-url")
                ?? productionBaseURLString
        }
    }

    nonisolated private static var productionBaseURLString: String {
        KboLiveEnvironment.productionBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    nonisolated private static var environmentBaseURLString: String? {
        environmentBaseURLString(named: "KBO_LIVE_BASE_URL")
    }

    nonisolated private static func environmentBaseURLString(named name: String) -> String? {
        guard let configured = ProcessInfo.processInfo.environment[name],
              normalizedURL(from: configured) != nil,
              isLegacyLocalBaseURL(configured) == false else {
            return nil
        }

        return configured
    }

    nonisolated private static func normalizedURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false,
              let url = URL(string: trimmed),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }

        return url
    }

    nonisolated private static func isLegacyLocalBaseURL(_ text: String) -> Bool {
        guard let url = normalizedURL(from: text) else {
            return false
        }

        return ["127.0.0.1", "localhost"].contains(url.host ?? "") && url.port == 3000
    }

    nonisolated private static func backendURL(baseURL: URL, path: String, apiPathPrefix: String) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let prefix = apiPathPrefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let effectivePrefix = shouldAppendPrefix(prefix, to: basePath) ? prefix : ""
        let pathParts = [basePath, effectivePrefix, requestPath].filter { $0.isEmpty == false }
        components.path = "/" + pathParts.joined(separator: "/")
        return components.url
    }

    nonisolated private static func shouldAppendPrefix(_ prefix: String, to basePath: String) -> Bool {
        guard prefix.isEmpty == false else {
            return false
        }

        guard basePath.isEmpty == false else {
            return true
        }

        return basePath != prefix && basePath.hasSuffix("/" + prefix) == false
    }
}
