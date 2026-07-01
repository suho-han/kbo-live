import Foundation
import Testing
@testable import KboLiveCore

struct GameRepositoryTests {
    @Test func repositoryMapsTodayGamesIntoDomain() async throws {
        let dto = GameDTO(
            gameId: "20260610HTHH0",
            date: "20260610",
            venue: "대전",
            startTime: "2026-06-10T18:30:00+09:00",
            status: .live,
            awayTeam: TeamDTO(id: "HT", name: "KIA"),
            homeTeam: TeamDTO(id: "HH", name: "한화"),
            score: ScoreDTO(away: 3, home: 2),
            inning: InningDTO(number: 7, half: .bottom),
            count: CountDTO(balls: 1, strikes: 2, outs: 2),
            bases: BasesDTO(first: true, second: false, third: true),
            current: CurrentMatchupDTO(batter: "최원준", pitcher: "김서현"),
            probablePitchers: ProbablePitchersDTO(
                away: ProbablePitcherDTO(name: "네일"),
                home: ProbablePitcherDTO(
                    name: "문동주",
                    record: PitcherSeasonSummaryDTO(wins: 8, losses: 3, era: 2.91, whip: 1.09)
                )
            ),
            recentPlay: "좌전 적시타",
            sourceMeta: SourceMetaDTO(rawStatusCode: "2", rawTopBottomCode: "B", fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        let repository = LiveGameRepository(
            apiClient: StubAPIClient(
                todayGames: TodayGamesResponseDTO(date: "20260610", games: [dto]),
                gameDetail: GameDetailResponseDTO(date: "20260610", game: dto),
                teamStandings: TeamStandingsResponseDTO(
                    date: "20260610",
                    standings: [
                        TeamStandingDTO(
                            teamId: "LG",
                            teamName: "LG",
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
        )

        let result = try await repository.fetchTodayGames(date: "2026-06-10")

        #expect(result.date == "20260610")
        #expect(result.games.count == 1)
        #expect(result.games[0].status == .live)
        #expect(result.games[0].current?.batter == "최원준")
        #expect(result.games[0].probablePitchers.home.record == PitcherSeasonSummary(wins: 8, losses: 3, era: 2.91, whip: 1.09))
    }

    @Test func repositoryMapsTeamStandingsIntoDomain() async throws {
        let repository = LiveGameRepository(
            apiClient: StubAPIClient(
                todayGames: TodayGamesResponseDTO(date: "20260610", games: []),
                gameDetail: GameDetailResponseDTO(date: "20260610", game: nil),
                teamStandings: TeamStandingsResponseDTO(
                    date: "20260610",
                    standings: [
                        TeamStandingDTO(
                            teamId: "LG",
                            teamName: "LG",
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
        )

        let result = try await repository.fetchTeamStandings(date: "2026-06-10")

        #expect(result.date == "20260610")
        #expect(result.standings.first?.team.id == "LG")
        #expect(result.standings.first?.recentTen == "7승0무3패")
    }

    @Test func repositoryMapsOptionalGameDetail() async throws {
        let repository = LiveGameRepository(
            apiClient: StubAPIClient(
                todayGames: TodayGamesResponseDTO(date: "20260610", games: []),
                gameDetail: GameDetailResponseDTO(date: "20260610", game: nil),
                teamStandings: TeamStandingsResponseDTO(date: "20260610", standings: [])
            )
        )

        let result = try await repository.fetchGameDetail(gameId: "missing", date: "2026-06-10")

        #expect(result.date == "20260610")
        #expect(result.game == nil)
    }
}

private struct StubAPIClient: KboLiveAPIClient, Sendable {
    let todayGames: TodayGamesResponseDTO
    let gameDetail: GameDetailResponseDTO
    let teamStandings: TeamStandingsResponseDTO

    func fetchTodayGames(date: String?) async throws -> TodayGamesResponseDTO {
        todayGames
    }

    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetailResponseDTO {
        gameDetail
    }

    func fetchTeamStandings(date: String?) async throws -> TeamStandingsResponseDTO {
        teamStandings
    }
}
