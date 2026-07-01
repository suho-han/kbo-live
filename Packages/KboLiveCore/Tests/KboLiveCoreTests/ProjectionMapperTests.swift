import Foundation
import Testing
@testable import KboLiveCore

struct ProjectionMapperTests {
    @Test func mapsScheduledGameToWidgetSnapshot() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(try #require(response.games.first))
        let snapshot = WidgetGameSnapshotMapper.map(game)

        #expect(snapshot.gameId == "20260610SKLG0")
        #expect(snapshot.awayTeamName == "SSG")
        #expect(snapshot.homeTeamName == "LG")
        #expect(snapshot.status == .scheduled)
        #expect(snapshot.inningText == "18:30 예정")
        #expect(snapshot.baseState == BasesState(first: false, second: false, third: false))
        #expect(snapshot.recentPlay == nil)
        #expect(snapshot.headline == "대표 경기")
        #expect(snapshot.contextText == "18:30 예정 · 잠실")
        #expect(snapshot.isFavoriteTeamGame == false)
        #expect(snapshot.fallbackKind == .none)
    }

    @Test func mapsFavoriteTeamGameToPersonalizedWidgetSnapshot() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(game, favoriteTeamID: "HH")

        #expect(snapshot.headline == "나의 팀 경기")
        #expect(snapshot.contextText == "한화 경기 · LIVE · 7회말 · 대전")
        #expect(snapshot.isFavoriteTeamGame == true)
        #expect(snapshot.fallbackKind == .none)
    }

    @Test func mapsFavoriteTeamNoGameWidgetFallback() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(
            game,
            favoriteTeamID: "LG",
            fallbackKind: .favoriteTeamNoGame
        )

        #expect(snapshot.headline == "응원팀 경기 없음")
        #expect(snapshot.contextText == "LG 오늘 경기 없음 · 대표 경기")
        #expect(snapshot.isFavoriteTeamGame == false)
        #expect(snapshot.fallbackKind == .favoriteTeamNoGame)
    }

    @Test func mapsNoFavoriteTeamSelectedWidgetFallback() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(game, fallbackKind: .favoriteTeamNotSelected)

        #expect(snapshot.headline == "응원팀을 선택하세요")
        #expect(snapshot.contextText == "대표 경기 · LIVE · 7회말 · 대전")
        #expect(snapshot.isFavoriteTeamGame == false)
        #expect(snapshot.fallbackKind == .favoriteTeamNotSelected)
    }

    @Test func mapsTodayGamesToFavoriteTeamWidgetSnapshot() throws {
        let response = try loadFixtureResponse()
        let todayGames = TodayGames(
            date: response.date,
            games: response.games.map { GameDTOMapper.map($0) }
        )

        let snapshot: WidgetGameSnapshot = try #require(
            WidgetGameSnapshotMapper.map(todayGames: todayGames, favoriteTeamID: "HH")
        )

        #expect(snapshot.gameId == "20260610HTHH0")
        #expect(snapshot.headline == "나의 팀 경기")
        #expect(snapshot.isFavoriteTeamGame == true)
    }

    @Test func mapsTodayGamesToNoFavoriteSelectedFallback() throws {
        let response = try loadFixtureResponse()
        let todayGames = TodayGames(
            date: response.date,
            games: response.games.map { GameDTOMapper.map($0) }
        )

        let snapshot: WidgetGameSnapshot = try #require(
            WidgetGameSnapshotMapper.map(todayGames: todayGames, favoriteTeamID: nil)
        )

        #expect(snapshot.headline == "응원팀을 선택하세요")
        #expect(snapshot.fallbackKind == .favoriteTeamNotSelected)
    }

    @Test func widgetSnapshotRoundTripsThroughJSON() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let snapshot = WidgetGameSnapshotMapper.map(game, favoriteTeamID: "HH")

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetGameSnapshot.self, from: data)

        #expect(decoded == snapshot)
    }

    @Test func mapsLiveGameToActivityState() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let state = ActivityGameStateMapper.map(game)

        #expect(state.awayScore == 3)
        #expect(state.homeScore == 2)
        #expect(state.status == .live)
        #expect(state.inningText == "7회말")
        #expect(state.outs == 2)
        #expect(state.hasRunnerOnFirst == true)
        #expect(state.hasRunnerOnSecond == false)
        #expect(state.hasRunnerOnThird == true)
        #expect(state.shortRecentPlay == "좌전 적시타")
    }

    @Test func mapsLiveGameToMenuBarSummary() throws {
        let response = try loadFixtureResponse()
        let game = GameDTOMapper.map(response.games[1])
        let summary = MenuBarGameSummaryMapper.map(game)

        #expect(summary.gameId == "20260610HTHH0")
        #expect(summary.status == .live)
        #expect(summary.isLive == true)
        #expect(summary.primaryText == "KIA 3:2 한화")
        #expect(summary.secondaryText == "LIVE · 7회말 · 2사")
        #expect(summary.recentPlay == "좌전 적시타")
    }

    @Test func truncatesLongRecentPlayForActivityState() {
        let game = makeGame(recentPlay: "오스틴의 좌중간 담장을 때리는 아주 긴 적시 2루타 설명")
        let state = ActivityGameStateMapper.map(game)

        #expect(state.shortRecentPlay == "오스틴의 좌중간 담장을 때리는 아주 긴 적…")
    }

    @Test func deduplicatesMenuBarStatusTokensWhenLiveHasNoInning() {
        let game = Game(
            id: "live-no-inning",
            date: "20260610",
            venue: "잠실",
            startTime: nil,
            status: .live,
            awayTeam: Team(id: "LG", name: "LG"),
            homeTeam: Team(id: "OB", name: "두산"),
            score: Score(away: 4, home: 3),
            inning: nil,
            count: CountState(balls: 1, strikes: 2, outs: 2),
            bases: BasesState(first: true, second: false, third: false),
            current: nil,
            probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        #expect(GameProjectionFormatter.menuBarSecondaryText(for: game) == "LIVE · 2사")
    }

    @Test func deduplicatesMenuBarStatusTokensWhenDelayed() {
        let game = Game(
            id: "delayed",
            date: "20260610",
            venue: "잠실",
            startTime: nil,
            status: .delayed,
            awayTeam: Team(id: "LG", name: "LG"),
            homeTeam: Team(id: "OB", name: "두산"),
            score: Score(away: 0, home: 0),
            inning: nil,
            count: nil,
            bases: nil,
            current: nil,
            probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        #expect(GameProjectionFormatter.menuBarSecondaryText(for: game) == "지연")
    }

    private func loadFixtureResponse() throws -> TodayGamesResponseDTO {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        return try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
    }

    private func makeGame(recentPlay: String?) -> Game {
        Game(
            id: "sample",
            date: "20260610",
            venue: "잠실",
            startTime: nil,
            status: .live,
            awayTeam: Team(id: "LG", name: "LG"),
            homeTeam: Team(id: "OB", name: "두산"),
            score: Score(away: 4, home: 3),
            inning: InningState(number: 9, half: .bottom),
            count: CountState(balls: 1, strikes: 2, outs: 2),
            bases: BasesState(first: true, second: true, third: false),
            current: CurrentMatchup(batter: "오스틴", pitcher: "박치국"),
            probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
            recentPlay: recentPlay,
            sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )
    }
}
