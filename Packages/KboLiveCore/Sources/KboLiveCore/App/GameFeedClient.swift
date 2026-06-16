import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct GameFeedClient: Sendable {
    public let repository: any GameRepository
    public let pollingInterval: Duration

    public init(
        repository: any GameRepository,
        pollingInterval: Duration = KboLiveEnvironment.defaultPollingInterval
    ) {
        self.repository = repository
        self.pollingInterval = pollingInterval
    }

    public static func live(
        environment: KboLiveEnvironment,
        session: any HTTPSession = URLSession.shared
    ) -> GameFeedClient {
        let apiClient = URLSessionKboLiveAPIClient(
            baseURL: environment.baseURL,
            apiPathPrefix: environment.apiPathPrefix,
            session: session
        )
        let repository = LiveGameRepository(apiClient: apiClient)
        return GameFeedClient(
            repository: repository,
            pollingInterval: environment.pollingInterval
        )
    }

    public static func live(
        baseURL: URL = KboLiveEnvironment.defaultBaseURL,
        apiPathPrefix: String = KboLiveEnvironment.defaultAPIPathPrefix,
        pollingInterval: Duration = KboLiveEnvironment.defaultPollingInterval,
        session: any HTTPSession = URLSession.shared
    ) -> GameFeedClient {
        live(
            environment: KboLiveEnvironment(
                baseURL: baseURL,
                apiPathPrefix: apiPathPrefix,
                pollingInterval: pollingInterval
            ),
            session: session
        )
    }

    public static func mock(
        todayGames: TodayGames,
        gameDetailsById: [String: GameDetail] = [:],
        pollingInterval: Duration = KboLiveEnvironment.defaultPollingInterval
    ) -> GameFeedClient {
        GameFeedClient(
            repository: MockGameRepository(
                todayGames: todayGames,
                gameDetailsById: gameDetailsById
            ),
            pollingInterval: pollingInterval
        )
    }

    public func fetchTodayGames(date: String? = nil) async throws -> TodayGames {
        try await repository.fetchTodayGames(date: date)
    }

    public func fetchGameDetail(gameId: String, date: String? = nil) async throws -> GameDetail {
        try await repository.fetchGameDetail(gameId: gameId, date: date)
    }

    public func streamTodayGames(date: String? = nil) -> AsyncThrowingStream<TodayGames, Error> {
        LiveGamePollingService(
            repository: repository,
            interval: pollingInterval
        ).streamTodayGames(date: date)
    }
}
