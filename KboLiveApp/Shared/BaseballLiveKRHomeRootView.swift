import SwiftUI
#if os(iOS)
import WidgetKit
#endif
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif
#if canImport(BaseballLiveKRDesignSystem)
import BaseballLiveKRDesignSystem
#endif
#if canImport(BaseballLiveKRFeatures)
import BaseballLiveKRFeatures
#endif

struct BaseballLiveKRHomeRootView: View {
    @StateObject private var viewModel: TodayGamesViewModel
    @StateObject private var liveActivityController = LiveGameActivityController()
    @ObservedObject private var settings: BackendSettingsModel
    @ObservedObject private var navigationModel: AppNavigationModel
    @ObservedObject private var updateChecker: AppUpdateCheckModel
    @Binding private var appearanceMode: KboAppearanceMode
    @State private var isShowingSettings = false

    init(
        viewModel: TodayGamesViewModel? = nil,
        settings: BackendSettingsModel = BackendSettingsModel(),
        navigationModel: AppNavigationModel = AppNavigationModel(),
        updateChecker: AppUpdateCheckModel = AppUpdateCheckModel(),
        appearanceMode: Binding<KboAppearanceMode> = .constant(.defaultValue)
    ) {
        _settings = ObservedObject(wrappedValue: settings)
        _navigationModel = ObservedObject(wrappedValue: navigationModel)
        _updateChecker = ObservedObject(wrappedValue: updateChecker)
        _appearanceMode = appearanceMode
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
                updateWidgetSnapshot(games: games)
                Task {
                    await liveActivityController.update(with: games)
                }
            }
            .onReceive(viewModel.$selectedTeamID) { _ in
                updateWidgetSnapshot(games: viewModel.games)
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
                        appearanceMode: $appearanceMode,
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
                .preferredColorScheme(appearanceMode.preferredColorScheme)
            }
    }

    private func applyBackendSettings() {
        Task {
            await viewModel.updateClient(settings.makeClient())
        }
    }

    private func updateWidgetSnapshot(games: [Game]) {
#if os(iOS)
        guard let snapshot = WidgetGameSnapshotMapper.map(
            todayGames: TodayGames(date: viewModel.activeDateString, games: games),
            favoriteTeamID: viewModel.selectedTeamID
        ) else {
            return
        }

        WidgetGameSnapshotStore().save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: "TodayGameWidget")
#endif
    }
}
