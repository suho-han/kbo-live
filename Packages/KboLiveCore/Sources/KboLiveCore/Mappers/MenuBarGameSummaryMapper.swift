import Foundation

public enum MenuBarGameSummaryMapper {
    public static func map(_ game: Game) -> MenuBarGameSummary {
        MenuBarGameSummary(
            gameId: game.id,
            status: game.status,
            isLive: game.status == .live,
            primaryText: GameProjectionFormatter.scoreLine(for: game),
            secondaryText: GameProjectionFormatter.menuBarSecondaryText(for: game),
            recentPlay: GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 48)
        )
    }
}
