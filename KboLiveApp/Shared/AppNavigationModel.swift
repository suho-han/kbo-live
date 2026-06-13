import Foundation
#if canImport(KboLiveCore)
import KboLiveCore
#endif

@MainActor
final class AppNavigationModel: ObservableObject {
    @Published var selectedGame: Game?

    func present(game: Game) {
        selectedGame = game
    }

    func dismissGameDetail() {
        selectedGame = nil
    }
}
