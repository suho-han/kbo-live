import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct GameFeedClient: Sendable {
    public let repository: any GameRepository
    public let pollingInterval: Duration

    public init(
        repository: any GameRepository,
        pollingInterval: Duration = BaseballLiveKREnvironment.defaultPollingInterval
    ) {
        self.repository = repository
        self.pollingInterval = pollingInterval
    }

    public static func live(
        environment: BaseballLiveKREnvironment,
        session: any HTTPSession = URLSession.shared
    ) -> GameFeedClient {
        let apiClient = URLSessionBaseballLiveKRAPIClient(
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
        baseURL: URL = BaseballLiveKREnvironment.defaultBaseURL,
        apiPathPrefix: String = BaseballLiveKREnvironment.defaultAPIPathPrefix,
        pollingInterval: Duration = BaseballLiveKREnvironment.defaultPollingInterval,
        session: any HTTPSession = URLSession.shared
    ) -> GameFeedClient {
        live(
            environment: BaseballLiveKREnvironment(
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
        pollingInterval: Duration = BaseballLiveKREnvironment.defaultPollingInterval
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

    public func fetchTeamStandings(date: String? = nil) async throws -> TeamStandings {
        try await repository.fetchTeamStandings(date: date)
    }

    public func streamTodayGames(date: String? = nil) -> AsyncThrowingStream<TodayGames, Error> {
        LiveGamePollingService(
            repository: repository,
            interval: pollingInterval
        ).streamTodayGames(date: date)
    }
}
