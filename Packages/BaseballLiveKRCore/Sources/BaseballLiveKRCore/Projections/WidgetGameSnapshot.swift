import Foundation

public struct WidgetGameSnapshot: Codable, Sendable, Equatable {
    public let gameId: String
    public let awayTeamName: String
    public let homeTeamName: String
    public let awayScore: Int
    public let homeScore: Int
    public let status: GameStatus
    public let inningText: String?
    public let baseState: BasesState?
    public let recentPlay: String?
    public let headline: String
    public let contextText: String?
    public let isFavoriteTeamGame: Bool
    public let fallbackKind: WidgetGameSnapshotFallbackKind

    public init(
        gameId: String,
        awayTeamName: String,
        homeTeamName: String,
        awayScore: Int,
        homeScore: Int,
        status: GameStatus,
        inningText: String?,
        baseState: BasesState?,
        recentPlay: String?,
        headline: String = "대표 경기",
        contextText: String? = nil,
        isFavoriteTeamGame: Bool = false,
        fallbackKind: WidgetGameSnapshotFallbackKind = .none
    ) {
        self.gameId = gameId
        self.awayTeamName = awayTeamName
        self.homeTeamName = homeTeamName
        self.awayScore = awayScore
        self.homeScore = homeScore
        self.status = status
        self.inningText = inningText
        self.baseState = baseState
        self.recentPlay = recentPlay
        self.headline = headline
        self.contextText = contextText
        self.isFavoriteTeamGame = isFavoriteTeamGame
        self.fallbackKind = fallbackKind
    }
}

public enum WidgetGameSnapshotFallbackKind: String, Codable, Sendable, Equatable {
    case none
    case favoriteTeamNoGame
    case favoriteTeamNotSelected
}
