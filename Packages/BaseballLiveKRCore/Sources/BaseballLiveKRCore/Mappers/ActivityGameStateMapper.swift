import Foundation

public enum ActivityGameStateMapper {
    public static func map(_ game: Game) -> ActivityGameState {
        ActivityGameState(
            awayScore: game.score.away,
            homeScore: game.score.home,
            status: ActivityStatus(rawValue: game.status.rawValue) ?? .unknown,
            inningText: GameProjectionFormatter.inningText(for: game),
            outs: game.count?.outs,
            hasRunnerOnFirst: game.bases?.first ?? false,
            hasRunnerOnSecond: game.bases?.second ?? false,
            hasRunnerOnThird: game.bases?.third ?? false,
            shortRecentPlay: GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 24)
        )
    }
}
