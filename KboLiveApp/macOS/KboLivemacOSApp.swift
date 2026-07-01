import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(KboLiveDesignSystem)
import KboLiveDesignSystem
#endif

@main
struct KboLivemacOSApp: App {
    private enum MainWindowLayout {
        static let minWidth = TodayGamesView.Layout.minimumWindowWidth
        static let minHeight: CGFloat = 720
        static let defaultWidth = TodayGamesView.Layout.minimumWindowWidth
        static let defaultHeight: CGFloat = 860
    }

#if canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif
    @StateObject private var viewModel: TodayGamesViewModel
    @StateObject private var settings = BackendSettingsModel()
    @StateObject private var navigationModel = AppNavigationModel()
    @StateObject private var updateChecker = AppUpdateCheckModel()
    @AppStorage("kboLiveFontScale") private var fontScale = Double(KboFontScale.defaultValue)
    @AppStorage(KboAppearanceMode.storageKey) private var appearanceModeRawValue = KboAppearanceMode.defaultValue.rawValue

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
        Window("Baseball LIVE KR", id: "main-window") {
            KboLiveHomeRootView(
                viewModel: viewModel,
                settings: settings,
                navigationModel: navigationModel,
                updateChecker: updateChecker,
                appearanceMode: appearanceModeBinding
            )
                .frame(
                    width: MainWindowLayout.minWidth
                )
                .frame(minHeight: MainWindowLayout.minHeight)
                .background(WindowWidthLimiter(width: MainWindowLayout.minWidth))
                .environment(\.kboFontScale, CGFloat(fontScale))
                .preferredColorScheme(appearanceMode.preferredColorScheme)
                .onAppear {
                    applyApplicationAppearance(appearanceMode)
                }
                .onChange(of: appearanceMode) { newValue in
                    applyApplicationAppearance(newValue)
                }
                .task {
                    updateChecker.startAutomaticChecks()
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
        .defaultSize(
            width: MainWindowLayout.defaultWidth,
            height: MainWindowLayout.defaultHeight
        )
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("보기") {
                Button("글씨 크게") {
                    adjustFontScale(by: KboFontScale.step)
                }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(CGFloat(fontScale) >= KboFontScale.maximum)

                Button("글씨 작게") {
                    adjustFontScale(by: -KboFontScale.step)
                }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(CGFloat(fontScale) <= KboFontScale.minimum)
            }
        }

        MenuBarExtra {
            MenuBarDashboardView(
                viewModel: viewModel,
                navigationModel: navigationModel
            )
            .environment(\.kboFontScale, CGFloat(fontScale))
            .preferredColorScheme(appearanceMode.preferredColorScheme)
        } label: {
            Label(menuBarTitle, systemImage: "baseball.fill")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                viewModel: viewModel,
                settings: settings,
                updateChecker: updateChecker,
                appearanceMode: appearanceModeBinding,
                onApplyBackendSettings: applyBackendSettings
            )
            .environment(\.kboFontScale, CGFloat(fontScale))
            .preferredColorScheme(appearanceMode.preferredColorScheme)
        }
    }

    private var appearanceMode: KboAppearanceMode {
        KboAppearanceMode.resolved(from: appearanceModeRawValue)
    }

    private var appearanceModeBinding: Binding<KboAppearanceMode> {
        Binding {
            KboAppearanceMode.resolved(from: appearanceModeRawValue)
        } set: { newValue in
            appearanceModeRawValue = newValue.rawValue
        }
    }

    private func adjustFontScale(by delta: CGFloat) {
        fontScale = Double(KboFontScale.clamped(CGFloat(fontScale) + delta))
    }

    private func applyBackendSettings() {
        Task {
            await viewModel.updateClient(settings.makeClient())
        }
    }

    private func applyApplicationAppearance(_ mode: KboAppearanceMode) {
#if canImport(AppKit)
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
#endif
    }

    private var menuBarTitle: String {
        if let favoriteGame = viewModel.favoriteGame {
            return GameProjectionFormatter.scoreLine(for: favoriteGame)
        }

        return viewModel.leagueGames.first.map { MenuBarGameSummaryMapper.map($0).primaryText } ?? "Baseball LIVE KR"
    }
}

#if canImport(AppKit)
private struct WindowWidthLimiter: NSViewRepresentable {
    let width: CGFloat

    func makeNSView(context: Context) -> NSView {
        WindowWidthLimitingView(width: width)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let nsView = nsView as? WindowWidthLimitingView else { return }

        nsView.width = width
    }
}

private final class WindowWidthLimitingView: NSView {
    var width: CGFloat {
        didSet {
            configureWindow()
        }
    }

    init(width: CGFloat) {
        self.width = width
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }

    private func configureWindow() {
        guard let window else { return }

        WindowWidthController.shared.apply(width: width, to: window)
    }
}

@MainActor
private final class WindowWidthController: NSObject, NSWindowDelegate {
    static let shared = WindowWidthController()

    private var width: CGFloat = .zero
    private weak var controlledWindow: NSWindow?
    private var isApplyingFrame = false

    func apply(width: CGFloat, to window: NSWindow) {
        self.width = width
        controlledWindow = window
        window.delegate = self
        window.minSize.width = width
        window.maxSize.width = width
        window.contentMinSize.width = width
        window.contentMaxSize.width = width
        clampWidth(of: window)
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard sender === controlledWindow else { return frameSize }

        return NSSize(width: width, height: frameSize.height)
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === controlledWindow else { return }

        clampWidth(of: window)
    }

    private func clampWidth(of window: NSWindow) {
        guard !isApplyingFrame else { return }

        let frame = window.frame
        guard abs(frame.width - width) > 0.5 else { return }

        isApplyingFrame = true
        window.setFrame(
            NSRect(x: frame.minX, y: frame.minY, width: width, height: frame.height),
            display: true
        )
        isApplyingFrame = false
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
