import Foundation
import KboLiveCore
import Testing
@testable import KboLiveFeatures

@MainActor
struct TodayGamesViewModelTests {
    @Test func loadOrdersGamesUsingSharedCoreRule() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(id: "final", status: .final, startHour: 18),
                            makeGame(id: "scheduled", status: .scheduled, startHour: 19),
                            makeGame(id: "live", status: .live, startHour: 17)
                        ]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in },
            now: { Date(timeIntervalSince1970: 1_781_254_800) }
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.visibleGames.map(\.id) == ["live", "scheduled", "final"])
        #expect(viewModel.lastUpdatedAt == Date(timeIntervalSince1970: 1_781_254_800))
    }

    @Test func setFilterNarrowsVisibleGames() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(id: "live", status: .live, startHour: 17),
                            makeGame(id: "delayed", status: .delayed, startHour: 18),
                            makeGame(id: "scheduled", status: .scheduled, startHour: 19)
                        ]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()
        viewModel.setFilter(.scheduled)

        #expect(viewModel.visibleGames.map(\.id) == ["scheduled", "delayed"])
    }

    @Test func loadStoresFriendlyFailureMessage() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(repository: FailingGameRepository()),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in },
            now: { Date(timeIntervalSince1970: 1_781_254_800) }
        )

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "서버에 연결할 수 없습니다."))
        #expect(viewModel.errorMessage == "서버에 연결할 수 없습니다.")
        #expect(viewModel.lastUpdatedAt == nil)
    }

    @Test func loadWithoutDatePreservesExplicitRequestDate() async {
        let repository = RecordingGameRepository(
            todayGames: TodayGames(
                date: "20260612",
                games: [makeGame(id: "live", status: .live, startHour: 17)]
            )
        )
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(repository: repository),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load(date: "2026-06-12")
        await viewModel.load()

        #expect(viewModel.requestDate == "2026-06-12")
        #expect(await repository.requestedDates == ["2026-06-12", "2026-06-12"])
    }
}

private func makeGame(id: String, status: GameStatus, startHour: Int) -> Game {
    let calendar = Calendar(identifier: .gregorian)
    let startTime = calendar.date(from: DateComponents(
        timeZone: TimeZone(identifier: "Asia/Seoul"),
        year: 2026,
        month: 6,
        day: 12,
        hour: startHour,
        minute: 30
    ))

    return Game(
        id: id,
        date: "20260612",
        venue: "잠실",
        startTime: startTime,
        status: status,
        awayTeam: Team(id: "LG", name: "LG"),
        homeTeam: Team(id: "OB", name: "두산"),
        score: Score(away: 0, home: 0),
        inning: nil,
        count: nil,
        bases: nil,
        current: nil,
        probablePitchers: ProbablePitchers(away: nil, home: nil),
        recentPlay: nil,
        sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-12T10:05:00.000Z")
    )
}

private struct FailingGameRepository: GameRepository, Sendable {
    func fetchTodayGames(date: String?) async throws -> TodayGames {
        throw TestError.offline
    }

    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetail {
        throw TestError.offline
    }
}

private actor RecordingGameRepository: GameRepository {
    let todayGames: TodayGames
    private(set) var requestedDates: [String?] = []

    init(todayGames: TodayGames) {
        self.todayGames = todayGames
    }

    func fetchTodayGames(date: String?) async throws -> TodayGames {
        requestedDates.append(date)
        return todayGames
    }

    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetail {
        GameDetail(date: todayGames.date, game: todayGames.games.first(where: { $0.id == gameId }))
    }
}

private enum TestError: LocalizedError {
    case offline

    var errorDescription: String? {
        switch self {
        case .offline:
            return "서버에 연결할 수 없습니다."
        }
    }
}
