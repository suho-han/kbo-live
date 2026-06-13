import SwiftUI
#if canImport(KboLiveCore)
import KboLiveCore
#endif

public struct GameDetailScreen: View {
    @StateObject private var viewModel: GameDetailViewModel

    public init(parentViewModel: TodayGamesViewModel, game: Game) {
        _viewModel = StateObject(wrappedValue: parentViewModel.makeDetailViewModel(for: game))
    }

    public var body: some View {
        GameDetailView(viewModel: viewModel)
    }
}
