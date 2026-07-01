import Foundation

public struct MockGameRepository: GameRepository, Sendable {
    public let todayGames: TodayGames
    public let gameDetailsById: [String: GameDetail]
    public let teamStandings: TeamStandings

    public init(
        todayGames: TodayGames,
        gameDetailsById: [String: GameDetail] = [:],
        teamStandings: TeamStandings? = nil
    ) {
        self.todayGames = todayGames
        self.gameDetailsById = gameDetailsById
        self.teamStandings = teamStandings ?? TeamStandings(date: todayGames.date, standings: [])
    }

    public func fetchTodayGames(date: String? = nil) async throws -> TodayGames {
        todayGames
    }

    public func fetchGameDetail(gameId: String, date: String? = nil) async throws -> GameDetail {
        gameDetailsById[gameId] ?? GameDetail(date: todayGames.date, game: nil)
    }

    public func fetchTeamStandings(date: String? = nil) async throws -> TeamStandings {
        teamStandings
    }
}
