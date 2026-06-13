import Foundation
#if canImport(KboLiveCore)
import KboLiveCore
#endif

enum AppRuntime {
    static func makeClient() -> GameFeedClient {
        if let baseURL {
            return GameFeedClient.live(baseURL: baseURL)
        }

        return GameFeedClient(
            repository: MockGameRepository(
                todayGames: SampleGameFactory.todayGames,
                gameDetailsById: sampleGameDetails
            ),
            pollingInterval: .seconds(30)
        )
    }

    private static var baseURL: URL? {
        if let configured = ProcessInfo.processInfo.environment["KBO_LIVE_BASE_URL"],
           let url = URL(string: configured) {
            return url
        }

        return nil
    }

    private static var sampleGameDetails: [String: GameDetail] {
        Dictionary(
            uniqueKeysWithValues: SampleGameFactory.todayGames.games.map { game in
                (game.id, GameDetail(date: SampleGameFactory.todayGames.date, game: game))
            }
        )
    }
}
