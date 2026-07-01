import Foundation
import Testing
@testable import BaseballLiveKRCore

struct GameFeedClientTests {
    @Test func fetchTodayGamesDelegatesToRepository() async throws {
        let game = makeGame(id: "game-1")
        let client = GameFeedClient.mock(
            todayGames: TodayGames(date: "20260610", games: [game])
        )

        let result = try await client.fetchTodayGames(date: "2026-06-10")

        #expect(result.date == "20260610")
        #expect(result.games == [game])
    }

    @Test func fetchGameDetailUsesMockDetailById() async throws {
        let game = makeGame(id: "game-1")
        let client = GameFeedClient.mock(
            todayGames: TodayGames(date: "20260610", games: [game]),
            gameDetailsById: [
                "game-1": GameDetail(date: "20260610", game: game)
            ]
        )

        let result = try await client.fetchGameDetail(gameId: "game-1", date: nil)

        #expect(result.game == game)
    }

    @Test func streamTodayGamesYieldsImmediately() async throws {
        let game = makeGame(id: "game-1")
        let client = GameFeedClient.mock(
            todayGames: TodayGames(date: "20260610", games: [game]),
            pollingInterval: .seconds(60)
        )
        var iterator = client.streamTodayGames(date: nil).makeAsyncIterator()

        let first = try await iterator.next()

        #expect(first?.games == [game])
    }

    @Test func liveFactoryUsesEnvironmentDefaults() {
        let client = GameFeedClient.live()

        #expect(client.pollingInterval == BaseballLiveKREnvironment.defaultPollingInterval)
        #expect(BaseballLiveKREnvironment().baseURL == BaseballLiveKREnvironment.defaultBaseURL)
        #expect(BaseballLiveKREnvironment.stagingBaseURL.absoluteString.isEmpty == false)
        #expect(BaseballLiveKREnvironment().apiPathPrefix == BaseballLiveKREnvironment.defaultAPIPathPrefix)
    }

    @Test func mockFactoryAllowsCustomPollingInterval() {
        let client = GameFeedClient.mock(
            todayGames: TodayGames(date: "20260610", games: []),
            pollingInterval: .seconds(45)
        )

        #expect(client.pollingInterval == .seconds(45))
    }
}

private func makeGame(id: String) -> Game {
    Game(
        id: id,
        date: "20260610",
        venue: "잠실",
        startTime: nil,
        status: .live,
        awayTeam: Team(id: "LG", name: "LG"),
        homeTeam: Team(id: "OB", name: "두산"),
        score: Score(away: 1, home: 0),
        inning: InningState(number: 1, half: .top),
        count: CountState(balls: 0, strikes: 0, outs: 0),
        bases: BasesState(first: false, second: false, third: false),
        current: nil,
        probablePitchers: ProbablePitchers(
            away: ProbablePitcher(name: nil),
            home: ProbablePitcher(name: nil)
        ),
        recentPlay: nil,
        sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
    )
}
