import Foundation
import Testing
@testable import KboLiveCore

struct LiveGamePollingServiceTests {
    @Test func pollingStreamYieldsImmediately() async throws {
        let repository = CountingRepository()
        let service = LiveGamePollingService(repository: repository, interval: .seconds(60))
        var iterator = service.streamTodayGames(date: "2026-06-10").makeAsyncIterator()

        let first = try await iterator.next()

        #expect(first?.date == "20260610")
        #expect(first?.games.first?.id == "game-1")
        let count = await repository.fetchCount
        #expect(count == 1)
    }
}

private actor CountingRepository: GameRepository {
    private(set) var fetchCount = 0

    func fetchTodayGames(date: String?) async throws -> TodayGames {
        fetchCount += 1
        return TodayGames(
            date: "20260610",
            games: [
                Game(
                    id: "game-\(fetchCount)",
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
                    probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
                    recentPlay: nil,
                    sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
                )
            ]
        )
    }

    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetail {
        GameDetail(date: "20260610", game: nil)
    }

    func fetchTeamStandings(date: String?) async throws -> TeamStandings {
        TeamStandings(date: "20260610", standings: [])
    }
}
