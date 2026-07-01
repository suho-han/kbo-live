import Foundation

public enum TeamStandingsDTOMapper {
    public static func map(_ dto: TeamStandingsResponseDTO) -> TeamStandings {
        TeamStandings(
            date: dto.date,
            standings: dto.standings.map(map)
        )
    }

    public static func map(_ dto: TeamStandingDTO) -> TeamStanding {
        TeamStanding(
            team: Team(id: dto.teamId, name: dto.teamName),
            wins: dto.wins,
            losses: dto.losses,
            draws: dto.draws,
            rank: dto.rank,
            streak: GameDTOMapper.nilIfBlank(dto.streak),
            winRate: GameDTOMapper.nilIfBlank(dto.winRate),
            recentTen: GameDTOMapper.nilIfBlank(dto.recentTen),
            gamesBack: GameDTOMapper.nilIfBlank(dto.gamesBack)
        )
    }
}
