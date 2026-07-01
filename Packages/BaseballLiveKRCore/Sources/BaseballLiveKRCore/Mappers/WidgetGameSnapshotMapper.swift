import Foundation

public enum WidgetGameSnapshotMapper {
    public static func map(
        _ game: Game,
        favoriteTeamID: String? = nil,
        fallbackKind: WidgetGameSnapshotFallbackKind = .none
    ) -> WidgetGameSnapshot {
        let isFavoriteTeamGame = favoriteTeamID.map { game.involves(teamID: $0) } ?? false
        let metadata = displayMetadata(
            for: game,
            favoriteTeamID: favoriteTeamID,
            isFavoriteTeamGame: isFavoriteTeamGame,
            fallbackKind: fallbackKind
        )

        return WidgetGameSnapshot(
            gameId: game.id,
            awayTeamName: game.awayTeam.name,
            homeTeamName: game.homeTeam.name,
            awayScore: game.score.away,
            homeScore: game.score.home,
            status: game.status,
            inningText: GameProjectionFormatter.inningText(for: game),
            baseState: game.bases,
            recentPlay: GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 32),
            headline: metadata.headline,
            contextText: metadata.contextText,
            isFavoriteTeamGame: isFavoriteTeamGame,
            fallbackKind: fallbackKind
        )
    }

    public static func map(
        todayGames: TodayGames,
        favoriteTeamID: String?
    ) -> WidgetGameSnapshot? {
        let orderedGames = todayGames.orderedGames(filter: .all, preferredTeamID: favoriteTeamID)

        if let favoriteTeamID {
            if let favoriteGame = orderedGames.first(where: { $0.involves(teamID: favoriteTeamID) }) {
                return map(favoriteGame, favoriteTeamID: favoriteTeamID)
            }

            return orderedGames.first.map {
                map($0, favoriteTeamID: favoriteTeamID, fallbackKind: .favoriteTeamNoGame)
            }
        }

        return orderedGames.first.map {
            map($0, fallbackKind: .favoriteTeamNotSelected)
        }
    }

    private static func displayMetadata(
        for game: Game,
        favoriteTeamID: String?,
        isFavoriteTeamGame: Bool,
        fallbackKind: WidgetGameSnapshotFallbackKind
    ) -> (headline: String, contextText: String?) {
        switch fallbackKind {
        case .favoriteTeamNotSelected:
            return (
                headline: "응원팀을 선택하세요",
                contextText: joined(["대표 경기", statusContext(for: game)])
            )
        case .favoriteTeamNoGame:
            let teamName = favoriteTeamID.flatMap(teamName(for:))
            return (
                headline: "응원팀 경기 없음",
                contextText: joined([teamName.map { "\($0) 오늘 경기 없음" }, "대표 경기"])
            )
        case .none:
            if isFavoriteTeamGame, let favoriteTeamID {
                return (
                    headline: "나의 팀 경기",
                    contextText: joined([teamName(for: favoriteTeamID).map { "\($0) 경기" }, statusContext(for: game)])
                )
            }

            return (
                headline: "대표 경기",
                contextText: statusContext(for: game)
            )
        }
    }

    private static func statusContext(for game: Game) -> String? {
        let statusText: String? = switch game.status {
        case .scheduled:
            nil
        case .live:
            "LIVE"
        case .final:
            "FINAL"
        case .delayed:
            "지연"
        case .cancelled:
            "취소"
        case .unknown:
            nil
        }

        return joined([statusText, GameProjectionFormatter.inningText(for: game), game.venue])
    }

    private static func teamName(for teamID: String) -> String? {
        KboTeamOption.all.first { $0.id == teamID }?.name
    }

    private static func joined(_ parts: [String?]) -> String? {
        let values = parts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .reduce(into: [String]()) { partialResult, part in
                if partialResult.contains(part) == false {
                    partialResult.append(part)
                }
            }

        return values.isEmpty ? nil : values.joined(separator: " · ")
    }
}
