import SwiftUI
#if canImport(KboLiveFeatures)
import KboLiveFeatures
#endif

struct KboLiveHomeRootView: View {
    @StateObject private var viewModel: TodayGamesViewModel
    @StateObject private var liveActivityController = LiveGameActivityController()
    @ObservedObject private var settings: BackendSettingsModel
    @ObservedObject private var navigationModel: AppNavigationModel
    @ObservedObject private var updateChecker: AppUpdateCheckModel
    @State private var isShowingSettings = false

    init(
        viewModel: TodayGamesViewModel? = nil,
        settings: BackendSettingsModel = BackendSettingsModel(),
        navigationModel: AppNavigationModel = AppNavigationModel(),
        updateChecker: AppUpdateCheckModel = AppUpdateCheckModel()
    ) {
        _settings = ObservedObject(wrappedValue: settings)
        _navigationModel = ObservedObject(wrappedValue: navigationModel)
        _updateChecker = ObservedObject(wrappedValue: updateChecker)
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: TodayGamesViewModel(client: settings.makeClient()))
        }
    }

    var body: some View {
        let activeGameID = liveActivityController.activeGameID

        TodayGamesView(
            viewModel: viewModel,
            onOpenSettings: {
                isShowingSettings = true
            },
            liveActivityState: { game in
                if activeGameID == game.id {
                    return .stop
                }

                return liveActivityController.canStart(game: game) ? .start : .unavailable
            },
            onToggleLiveActivity: { game in
                Task {
                    await liveActivityController.toggle(for: game)
                }
            }
        )
            .onReceive(viewModel.$games) { games in
                Task {
                    await liveActivityController.update(with: games)
                }
            }
            .sheet(item: $navigationModel.selectedGame) { game in
                NavigationStack {
                    GameDetailScreen(parentViewModel: viewModel, game: game)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("닫기") {
                                    navigationModel.dismissGameDetail()
                                }
                            }
                        }
                }
                .frame(minWidth: 760, minHeight: 680)
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    AppSettingsView(
                        viewModel: viewModel,
                        settings: settings,
                        updateChecker: updateChecker,
                        onApplyBackendSettings: applyBackendSettings
                    )
                    .navigationTitle("설정")
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("닫기") {
                                isShowingSettings = false
                            }
                        }
                    }
                }
                .frame(minWidth: 420, minHeight: 320)
            }
    }

    private func applyBackendSettings() {
        Task {
            await viewModel.updateClient(settings.makeClient())
        }
    }
}
