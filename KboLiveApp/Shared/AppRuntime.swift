import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(KboLiveCore)
import KboLiveCore
#endif

enum AppRuntime {
    static func makeClient() -> GameFeedClient {
        GameFeedClient.live(baseURL: backendBaseURL)
    }

    static func makeClient(baseURL: URL) -> GameFeedClient {
        GameFeedClient.live(baseURL: baseURL)
    }

    static var backendBaseURL: URL {
        return BackendSettingsModel.resolvedBaseURL()
    }
}

@MainActor
final class AppUpdateCheckModel: ObservableObject {
    @Published var isShowingUpdateAlert = false
    @Published private(set) var alertMessage = ""
    @Published private(set) var lastCheckedAt: Date?
    @Published private(set) var state: State = .idle

    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(String)
        case noPublishedRelease
        case failed(String)
    }

    private let latestReleaseURL = URL(string: "https://api.github.com/repos/suho-han/kbo-live/releases/latest")!
    private let releasesPageURL = URL(string: "https://github.com/suho-han/kbo-live/releases")!
    private var releasePageURL: URL?
    private var hasCheckedThisLaunch = false
    private var automaticCheckTask: Task<Void, Never>?
    private var lastAlertedReleaseTagName: String?

    private nonisolated static let automaticCheckIntervalNanoseconds: UInt64 = 60 * 60 * 1_000_000_000

    var lastCheckedText: String {
        guard let lastCheckedAt else {
            return "아직 확인하지 않음"
        }

        return Self.lastCheckedFormatter.string(from: lastCheckedAt)
    }

    func checkOnLaunch() async {
        guard hasCheckedThisLaunch == false else { return }
        hasCheckedThisLaunch = true
        await checkForUpdates()
    }

    func startAutomaticChecks() {
        guard automaticCheckTask == nil else { return }

        automaticCheckTask = Task { [weak self] in
            await self?.checkOnLaunch()

            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: Self.automaticCheckIntervalNanoseconds)
                } catch {
                    return
                }

                await self?.checkForUpdates()
            }
        }
    }

    func checkForUpdates() async {
        guard state != .checking else { return }

        state = .checking

        do {
            let release = try await fetchLatestRelease()
            lastCheckedAt = Date()

            if isNewerVersion(release.version, than: currentVersion) {
                releasePageURL = release.htmlURL
                let title = release.name ?? release.tagName
                alertMessage = "\(title)를 다운로드할 수 있습니다. 현재 버전은 \(currentVersion)입니다."
                state = .updateAvailable(title)
                if lastAlertedReleaseTagName != release.tagName {
                    lastAlertedReleaseTagName = release.tagName
                    isShowingUpdateAlert = true
                }
            } else {
                releasePageURL = release.htmlURL
                state = .upToDate
            }
        } catch UpdateCheckError.noPublishedRelease {
            lastCheckedAt = Date()
            releasePageURL = releasesPageURL
            state = .noPublishedRelease
        } catch {
            lastCheckedAt = Date()
            state = .failed("업데이트 정보를 확인할 수 없습니다.")
        }
    }

    func openReleasePage() {
        guard let releasePageURL else { return }
#if canImport(AppKit)
        NSWorkspace.shared.open(releasePageURL)
#endif
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: latestReleaseURL)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            if (response as? HTTPURLResponse)?.statusCode == 404 {
                throw UpdateCheckError.noPublishedRelease
            }

            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private func isNewerVersion(_ candidate: String, than current: String) -> Bool {
        let candidateParts = normalizedVersionParts(candidate)
        let currentParts = normalizedVersionParts(current)
        let count = max(candidateParts.count, currentParts.count)

        for index in 0..<count {
            let candidateValue = index < candidateParts.count ? candidateParts[index] : 0
            let currentValue = index < currentParts.count ? currentParts[index] : 0

            if candidateValue != currentValue {
                return candidateValue > currentValue
            }
        }

        return false
    }

    private func normalizedVersionParts(_ version: String) -> [Int] {
        version
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            .split(separator: ".")
            .map { part in
                let digits = part.prefix { $0.isNumber }
                return Int(digits) ?? 0
            }
    }

    private static let lastCheckedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

private enum UpdateCheckError: Error {
    case noPublishedRelease
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let htmlURL: URL

    var version: String { tagName }

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlURL = "html_url"
    }
}
