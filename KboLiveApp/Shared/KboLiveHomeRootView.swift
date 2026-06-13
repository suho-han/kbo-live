import SwiftUI
#if canImport(KboLiveFeatures)
import KboLiveFeatures
#endif

struct KboLiveHomeRootView: View {
    @StateObject private var viewModel: TodayGamesViewModel
    @ObservedObject private var navigationModel: AppNavigationModel

    init(
        viewModel: TodayGamesViewModel? = nil,
        navigationModel: AppNavigationModel = AppNavigationModel()
    ) {
        _navigationModel = ObservedObject(wrappedValue: navigationModel)
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: TodayGamesViewModel(client: AppRuntime.makeClient()))
        }
    }

    var body: some View {
        TodayGamesView(viewModel: viewModel)
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
    }
}
