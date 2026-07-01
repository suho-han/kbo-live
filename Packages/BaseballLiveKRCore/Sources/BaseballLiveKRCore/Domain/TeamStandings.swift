import Foundation

public struct TeamStandings: Sendable, Equatable, Hashable {
    public let date: String
    public let standings: [TeamStanding]

    public init(date: String, standings: [TeamStanding]) {
        self.date = date
        self.standings = standings
    }
}

public struct TeamStanding: Identifiable, Sendable, Equatable, Hashable {
    public let team: Team
    public let wins: Int
    public let losses: Int
    public let draws: Int
    public let rank: Int?
    public let streak: String?
    public let winRate: String?
    public let recentTen: String?
    public let gamesBack: String?

    public var id: String { team.id }

    public init(
        team: Team,
        wins: Int,
        losses: Int,
        draws: Int,
        rank: Int? = nil,
        streak: String? = nil,
        winRate: String? = nil,
        recentTen: String? = nil,
        gamesBack: String? = nil
    ) {
        self.team = team
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.rank = rank
        self.streak = streak
        self.winRate = winRate
        self.recentTen = recentTen
        self.gamesBack = gamesBack
    }
}
