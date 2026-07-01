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
            filter: .all,
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in },
            now: { Date(timeIntervalSince1970: 1_781_254_800) }
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.visibleGames.map(\.id) == ["live", "scheduled", "final"])
        #expect(viewModel.lastUpdatedAt == Date(timeIntervalSince1970: 1_781_254_800))
    }

    @Test func initialFilterPrefersLiveGames() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(id: "scheduled", status: .scheduled, startHour: 19),
                            makeGame(id: "live", status: .live, startHour: 17)
                        ]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        #expect(viewModel.filter == .live)
        #expect(viewModel.visibleGames.map(\.id) == ["live"])
    }

    @Test func initialFilterFallsBackToScheduledWhenNoLiveGames() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(id: "final", status: .final, startHour: 18),
                            makeGame(id: "scheduled", status: .scheduled, startHour: 19)
                        ]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        #expect(viewModel.filter == .scheduled)
        #expect(viewModel.visibleGames.map(\.id) == ["scheduled"])
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

    @Test func selectedTeamGameAppearsFirstInLeagueList() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(
                                id: "live-other",
                                status: .live,
                                startHour: 17,
                                awayTeam: Team(id: "KT", name: "KT"),
                                homeTeam: Team(id: "NC", name: "NC")
                            ),
                            makeGame(
                                id: "scheduled-favorite",
                                status: .scheduled,
                                startHour: 19,
                                awayTeam: Team(id: "LG", name: "LG"),
                                homeTeam: Team(id: "OB", name: "두산")
                            ),
                            makeGame(
                                id: "final-other",
                                status: .final,
                                startHour: 18,
                                awayTeam: Team(id: "HH", name: "한화"),
                                homeTeam: Team(id: "SS", name: "삼성")
                            )
                        ]
                    )
                )
            ),
            filter: .all,
            selectedTeamID: "LG",
            loadSelectedTeamID: { "LG" },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        #expect(viewModel.leagueGames.map { $0.id } == ["scheduled-favorite", "live-other", "final-other"])
        #expect(viewModel.visibleGames.map { $0.id } == ["scheduled-favorite", "live-other", "final-other"])
    }

    @Test func dashboardSummaryCountsGameStates() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(id: "live", status: .live, startHour: 17),
                            makeGame(id: "scheduled", status: .scheduled, startHour: 18),
                            makeGame(id: "delayed", status: .delayed, startHour: 19),
                            makeGame(id: "final", status: .final, startHour: 20),
                            makeGame(id: "cancelled", status: .cancelled, startHour: 21)
                        ]
                    )
                )
            ),
            filter: .all,
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        let summary = viewModel.dashboardSummary
        #expect(summary.totalGames == 5)
        #expect(summary.liveGames == 1)
        #expect(summary.scheduledGames == 2)
        #expect(summary.finalGames == 2)
        #expect(summary.headline == "LG 0:0 두산")
        #expect(summary.detail == "진행 중 · 잠실 · 전체 5경기 · 진행 1 · 예정 2 · 종료 2")
    }

    @Test func dashboardSummaryFocusesSelectedTeamGame() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(
                                id: "favorite",
                                status: .scheduled,
                                startHour: 19,
                                awayTeam: Team(id: "LG", name: "LG"),
                                homeTeam: Team(id: "OB", name: "두산")
                            ),
                            makeGame(
                                id: "other-live",
                                status: .live,
                                startHour: 17,
                                awayTeam: Team(id: "KT", name: "KT"),
                                homeTeam: Team(id: "NC", name: "NC")
                            )
                        ]
                    )
                )
            ),
            filter: .all,
            selectedTeamID: "LG",
            loadSelectedTeamID: { "LG" },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        let summary = viewModel.dashboardSummary
        #expect(summary.headline == "LG vs 두산")
        #expect(summary.detail == "19:30 예정 · 잠실 · 전체 2경기 · 진행 1 · 예정 1 · 종료 0")
    }

    @Test func dashboardSummaryKeepsSelectedTeamNoGameCopy() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(
                                id: "other-live",
                                status: .live,
                                startHour: 17,
                                awayTeam: Team(id: "KT", name: "KT"),
                                homeTeam: Team(id: "NC", name: "NC")
                            )
                        ]
                    )
                )
            ),
            filter: .all,
            selectedTeamID: "LG",
            loadSelectedTeamID: { "LG" },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        let summary = viewModel.dashboardSummary
        #expect(summary.headline == "오늘은 LG 경기가 없습니다")
        #expect(summary.detail == "전체 1경기 · 진행 1 · 예정 0 · 종료 0")
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

    @Test func loadStoresTeamStandings() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: MockGameRepository(
                    todayGames: TodayGames(date: "20260612", games: []),
                    teamStandings: TeamStandings(
                        date: "20260612",
                        standings: [
                            TeamStanding(
                                team: Team(id: "LG", name: "LG"),
                                wins: 41,
                                losses: 24,
                                draws: 0,
                                rank: 1,
                                streak: "2승",
                                winRate: "0.631",
                                recentTen: "7승0무3패",
                                gamesBack: "0"
                            )
                        ]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        #expect(viewModel.standingsState == .loaded)
        #expect(viewModel.standings.first?.team.id == "LG")
        #expect(viewModel.standings.first?.recentTen == "7승0무3패")
    }

    @Test func standingsFailureDoesNotFailLoadedGames() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: StandingsFailingRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [makeGame(id: "live", status: .live, startHour: 17)]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.games.map(\.id) == ["live"])
        #expect(viewModel.standingsState == .failed(message: "서버에 연결할 수 없습니다."))
    }

    @Test func gamesFailureDoesNotBlockLoadedStandings() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: GamesFailingStandingsRepository(
                    teamStandings: TeamStandings(
                        date: "20260612",
                        standings: [
                            TeamStanding(
                                team: Team(id: "LG", name: "LG"),
                                wins: 41,
                                losses: 24,
                                draws: 0,
                                rank: 1,
                                streak: "2승"
                            )
                        ]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "서버에 연결할 수 없습니다."))
        #expect(viewModel.standingsState == .loaded)
        #expect(viewModel.standings.map(\.team.id) == ["LG"])
    }

    @Test func standingsFailureUsesGameRecordFallback() async {
        let viewModel = TodayGamesViewModel(
            client: GameFeedClient(
                repository: StandingsFailingRepository(
                    todayGames: TodayGames(
                        date: "20260612",
                        games: [
                            makeGame(
                                id: "fallback",
                                status: .live,
                                startHour: 17,
                                teamRecords: TeamRecords(
                                    away: TeamRecordSummary(wins: 39, losses: 24, draws: 2, rank: 2, streak: "1승"),
                                    home: TeamRecordSummary(wins: 41, losses: 22, draws: 1, rank: 1, streak: "3승")
                                )
                            )
                        ]
                    )
                )
            ),
            loadSelectedTeamID: { nil },
            saveSelectedTeamID: { _ in }
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.standingsState == .loaded)
        #expect(viewModel.standings.map(\.team.id) == ["OB", "LG"])
        #expect(viewModel.standings.first?.rank == 1)
        #expect(viewModel.standings.first?.streak == "3승")
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
        let requestedDates = await repository.requestedDates
        #expect(requestedDates.count >= 2)
        #expect(requestedDates.allSatisfy { $0 == "2026-06-12" })
    }
}

private func makeGame(
    id: String,
    status: GameStatus,
    startHour: Int,
    awayTeam: Team = Team(id: "LG", name: "LG"),
    homeTeam: Team = Team(id: "OB", name: "두산"),
    teamRecords: TeamRecords? = nil
) -> Game {
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
        awayTeam: awayTeam,
        homeTeam: homeTeam,
        score: Score(away: 0, home: 0),
        inning: nil,
        count: nil,
        bases: nil,
        current: nil,
        probablePitchers: ProbablePitchers(
            away: ProbablePitcher(name: nil),
            home: ProbablePitcher(name: nil)
        ),
        recentPlay: nil,
        teamRecords: teamRecords,
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

    func fetchTeamStandings(date: String?) async throws -> TeamStandings {
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

    func fetchTeamStandings(date: String?) async throws -> TeamStandings {
        TeamStandings(date: todayGames.date, standings: [])
    }
}

private struct StandingsFailingRepository: GameRepository, Sendable {
    let todayGames: TodayGames

    func fetchTodayGames(date: String?) async throws -> TodayGames {
        todayGames
    }

    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetail {
        GameDetail(date: todayGames.date, game: todayGames.games.first(where: { $0.id == gameId }))
    }

    func fetchTeamStandings(date: String?) async throws -> TeamStandings {
        throw TestError.offline
    }
}

private struct GamesFailingStandingsRepository: GameRepository, Sendable {
    let teamStandings: TeamStandings

    func fetchTodayGames(date: String?) async throws -> TodayGames {
        throw TestError.offline
    }

    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetail {
        throw TestError.offline
    }

    func fetchTeamStandings(date: String?) async throws -> TeamStandings {
        teamStandings
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
