import Foundation

public struct TeamStandingsResponseDTO: Decodable, Sendable {
    public let date: String
    public let standings: [TeamStandingDTO]

    public init(date: String, standings: [TeamStandingDTO]) {
        self.date = date
        self.standings = standings
    }
}

public struct TeamStandingDTO: Decodable, Identifiable, Sendable {
    public let teamId: String
    public let teamName: String
    public let wins: Int
    public let losses: Int
    public let draws: Int
    public let rank: Int?
    public let streak: String?
    public let winRate: String?
    public let recentTen: String?
    public let gamesBack: String?

    public var id: String { teamId }

    public init(
        teamId: String,
        teamName: String,
        wins: Int,
        losses: Int,
        draws: Int,
        rank: Int? = nil,
        streak: String? = nil,
        winRate: String? = nil,
        recentTen: String? = nil,
        gamesBack: String? = nil
    ) {
        self.teamId = teamId
        self.teamName = teamName
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
