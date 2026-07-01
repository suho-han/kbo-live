import Foundation
#if canImport(KboLiveCore)
import KboLiveCore
#endif

@MainActor
final class BackendSettingsModel: ObservableObject {
    enum BackendPreset: String, CaseIterable, Identifiable {
        case local
        case staging
        case production

        var id: String { rawValue }

        var title: String {
            switch self {
            case .local:
                return "Local"
            case .staging:
                return "Staging(Beta)"
            case .production:
                return "Production"
            }
        }

        var description: String {
            switch self {
            case .local:
                return "현재 Mac에서 실행 중인 packaged backend"
            case .staging:
                return "운영 후보 backend 베타 환경"
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
    @Published private(set) var validationState: ValidationState = .idle

    nonisolated(unsafe) static let presetPolicy = BackendPresetPolicy<BackendPreset>(
        displayOrder: [.production, .staging, .local],
        selectablePresets: [.production]
    )

    private let defaults: UserDefaults
    private let presetKey = "kbo-live.backend-preset"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedPreset = defaults.string(forKey: presetKey).flatMap(BackendPreset.init(rawValue:)) ?? Self.defaultPreset
        let resolvedPreset = Self.resolvedPreset(from: storedPreset)
        self.selectedPreset = resolvedPreset
    }

    var hasEnvironmentBaseURL: Bool {
        Self.environmentBaseURLString != nil
    }

    var effectiveBaseURL: URL {
        Self.baseURL(for: selectedPreset, defaults: defaults) ?? Self.resolvedBaseURL(defaults: defaults)
    }

    var selectedPresetTitle: String {
        return selectedPreset.title
    }

    var orderedPresets: [BackendPreset] {
        Self.presetPolicy.displayOrder
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

    func isPresetSelectable(_ preset: BackendPreset) -> Bool {
        Self.presetPolicy.isSelectable(preset)
    }

    @discardableResult
    func selectPreset(_ preset: BackendPreset) -> Bool {
        guard isPresetSelectable(preset) || preset == selectedPreset else {
            return false
        }

        selectedPreset = preset
        validationState = .idle

        return true
    }

    func save() -> Bool {
        defaults.set(selectedPreset.rawValue, forKey: presetKey)
        defaults.removeObject(forKey: KboLiveEnvironment.backendBaseURLDefaultsKey)

        validationState = .idle
        return true
    }

    func reset() {
        defaults.removeObject(forKey: presetKey)
        defaults.removeObject(forKey: KboLiveEnvironment.backendBaseURLDefaultsKey)
        selectedPreset = Self.defaultPreset
        validationState = .idle
    }

    func checkHealth() async {
        guard let url = Self.backendURL(baseURL: effectiveBaseURL, path: "ready") else {
            validationState = .unavailable("백엔드 URL을 만들 수 없습니다.")
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

}
