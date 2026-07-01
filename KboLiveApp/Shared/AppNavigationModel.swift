import Foundation
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
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
