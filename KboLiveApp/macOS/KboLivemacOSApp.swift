import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@main
struct KboLivemacOSApp: App {
#if canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif
    @StateObject private var viewModel: TodayGamesViewModel
    @StateObject private var settings = BackendSettingsModel()
    @StateObject private var navigationModel = AppNavigationModel()
    @StateObject private var updateChecker = AppUpdateChecker()

    init() {
        let settings = BackendSettingsModel()
        let viewModel = TodayGamesViewModel(client: settings.makeClient())
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: viewModel)

        Task {
            await viewModel.loadIfNeeded()
        }
    }

    var body: some Scene {
        Window("KBO Live", id: "main-window") {
            KboLiveHomeRootView(
                viewModel: viewModel,
                settings: settings,
                navigationModel: navigationModel
            )
                .frame(minWidth: 420, minHeight: 720)
                .task {
                    await updateChecker.checkOnLaunch()
                }
                .alert("업데이트가 있습니다.", isPresented: $updateChecker.isShowingUpdateAlert) {
                    Button("다운로드") {
                        updateChecker.openReleasePage()
                    }

                    Button("나중에", role: .cancel) {}
                } message: {
                    Text(updateChecker.alertMessage)
                }
        }

        MenuBarExtra {
            MenuBarDashboardView(
                viewModel: viewModel,
                navigationModel: navigationModel
            )
        } label: {
            Label(menuBarTitle, systemImage: "baseball.fill")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                viewModel: viewModel,
                settings: settings,
                onApplyBackendSettings: applyBackendSettings
            )
        }
    }

    private func applyBackendSettings() {
        Task {
            await viewModel.updateClient(settings.makeClient())
        }
    }

    private var menuBarTitle: String {
        if let favoriteGame = viewModel.favoriteGame {
            return GameProjectionFormatter.scoreLine(for: favoriteGame)
        }

        return viewModel.leagueGames.first.map { MenuBarGameSummaryMapper.map($0).primaryText } ?? "KBO Live"
    }
}

#if canImport(AppKit)
@MainActor
private final class AppUpdateChecker: ObservableObject {
    @Published var isShowingUpdateAlert = false
    @Published private(set) var alertMessage = ""

    private let latestReleaseURL = URL(string: "https://api.github.com/repos/suho-han/kbo-live/releases/latest")!
    private var releasePageURL: URL?
    private var hasCheckedThisLaunch = false

    func checkOnLaunch() async {
        guard hasCheckedThisLaunch == false else { return }
        hasCheckedThisLaunch = true

        do {
            let release = try await fetchLatestRelease()
            guard isNewerVersion(release.version, than: currentVersion) else { return }

            releasePageURL = release.htmlURL
            alertMessage = "\(release.name ?? release.tagName)를 다운로드할 수 있습니다. 현재 버전은 \(currentVersion)입니다."
            isShowingUpdateAlert = true
        } catch {
            return
        }
    }

    func openReleasePage() {
        guard let releasePageURL else { return }
        NSWorkspace.shared.open(releasePageURL)
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

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
