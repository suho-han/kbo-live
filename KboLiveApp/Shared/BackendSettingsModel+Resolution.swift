import Foundation
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif

extension BackendSettingsModel {
    nonisolated static var defaultBaseURLString: String {
        BaseballLiveKREnvironment.defaultBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    nonisolated static var defaultStagingBaseURLString: String {
        BaseballLiveKREnvironment.stagingBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    nonisolated static func resolvedBaseURL(defaults: UserDefaults = .standard) -> URL {
        if let url = normalizedURL(from: resolvedBaseURLString(defaults: defaults)) {
            return url
        }

        return BaseballLiveKREnvironment.productionBaseURL
    }

    nonisolated static func backendURL(baseURL: URL, path: String) -> URL? {
        backendURL(
            baseURL: baseURL,
            path: path,
            apiPathPrefix: BaseballLiveKREnvironment.defaultAPIPathPrefix
        )
    }

    nonisolated static func baseURL(for preset: BackendPreset, defaults: UserDefaults) -> URL? {
        guard let urlString = baseURLString(for: preset, defaults: defaults) else {
            return nil
        }

        return normalizedURL(from: urlString)
    }

    nonisolated static func resolvedBaseURLString(defaults: UserDefaults) -> String {
        if let environmentBaseURLString {
            return environmentBaseURLString
        }

        let storedPreset = defaults.string(forKey: "kbo-live.backend-preset")
            .flatMap(BackendPreset.init(rawValue:)) ?? defaultPreset
        let preset = resolvedPreset(from: storedPreset)

        if let presetURL = baseURLString(for: preset, defaults: defaults) {
            return presetURL
        }

        return productionBaseURLString
    }

    nonisolated static func resolvedPreset(from storedPreset: BackendPreset) -> BackendPreset {
        if environmentBaseURLString != nil {
            return .local
        }

        return presetPolicy.isSelectable(storedPreset) ? storedPreset : .production
    }

    nonisolated static func baseURLString(for preset: BackendPreset, defaults: UserDefaults) -> String? {
        switch preset {
        case .local:
            return environmentBaseURLString
                ?? defaults.string(forKey: "kbo-live.backend-local-base-url")
                ?? defaultBaseURLString
        case .staging:
            return environmentBaseURLString(named: "KBO_LIVE_STAGING_BASE_URL")
                ?? defaults.string(forKey: "kbo-live.backend-staging-base-url")
                ?? defaultStagingBaseURLString
        case .production:
            return environmentBaseURLString(named: "KBO_LIVE_PRODUCTION_BASE_URL")
                ?? defaults.string(forKey: "kbo-live.backend-production-base-url")
                ?? productionBaseURLString
        }
    }

    nonisolated static var productionBaseURLString: String {
        BaseballLiveKREnvironment.productionBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    nonisolated static var defaultPreset: BackendPreset {
        environmentBaseURLString == nil ? .production : .local
    }

    nonisolated static var environmentBaseURLString: String? {
        environmentBaseURLString(named: "KBO_LIVE_BASE_URL")
    }

    nonisolated static func environmentBaseURLString(named name: String) -> String? {
        guard let configured = ProcessInfo.processInfo.environment[name],
              normalizedURL(from: configured) != nil else {
            return nil
        }

        return configured
    }

    nonisolated static func normalizedURL(from text: String) -> URL? {
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

    nonisolated static func backendURL(baseURL: URL, path: String, apiPathPrefix: String) -> URL? {
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

    nonisolated static func shouldAppendPrefix(_ prefix: String, to basePath: String) -> Bool {
        guard prefix.isEmpty == false else {
            return false
        }

        guard basePath.isEmpty == false else {
            return true
        }

        return basePath != prefix && basePath.hasSuffix("/" + prefix) == false
    }
}
