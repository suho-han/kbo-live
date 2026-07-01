import Foundation

public struct TodayGames: Sendable, Equatable {
    public let date: String
    public let games: [Game]

    public init(date: String, games: [Game]) {
        self.date = date
        self.games = games
    }
}

public struct GameDetail: Sendable, Equatable {
    public let date: String
    public let game: Game?

    public init(date: String, game: Game?) {
        self.date = date
        self.game = game
    }
}
