import Foundation
import Testing
@testable import BaseballLiveKRCore

struct TodayGamesListTests {
    @Test func orderedGamesPrioritizesLiveThenScheduledStates() {
        let todayGames = TodayGames(
            date: "20260610",
            games: [
                makeGame(id: "final", status: .final, startHour: 18),
                makeGame(id: "scheduled-late", status: .scheduled, startHour: 19),
                makeGame(id: "live", status: .live, startHour: 18),
                makeGame(id: "delayed", status: .delayed, startHour: 17),
                makeGame(id: "scheduled-early", status: .scheduled, startHour: 17),
                makeGame(id: "cancelled", status: .cancelled, startHour: 16)
            ]
        )

        let orderedIds = todayGames.orderedGames().map(\.id)

        #expect(orderedIds == [
            "live",
            "scheduled-early",
            "scheduled-late",
            "delayed",
            "final",
            "cancelled"
        ])
    }

    @Test func scheduledFilterIncludesDelayedGames() {
        let todayGames = TodayGames(
            date: "20260610",
            games: [
                makeGame(id: "live", status: .live, startHour: 18),
                makeGame(id: "scheduled", status: .scheduled, startHour: 17),
                makeGame(id: "delayed", status: .delayed, startHour: 19),
                makeGame(id: "final", status: .final, startHour: 16)
            ]
        )

        let orderedIds = todayGames.orderedGames(filter: .scheduled).map(\.id)

        #expect(orderedIds == ["scheduled", "delayed"])
    }

    @Test func finalFilterIncludesCancelledGames() {
        let todayGames = TodayGames(
            date: "20260610",
            games: [
                makeGame(id: "cancelled", status: .cancelled, startHour: 16),
                makeGame(id: "final", status: .final, startHour: 18),
                makeGame(id: "live", status: .live, startHour: 17)
            ]
        )

        let orderedIds = todayGames.orderedGames(filter: .final).map(\.id)

        #expect(orderedIds == ["final", "cancelled"])
    }

    @Test func orderedGamesPrioritizesPreferredTeamBeforeStatusOrder() {
        let todayGames = TodayGames(
            date: "20260610",
            games: [
                makeGame(
                    id: "live-other",
                    status: .live,
                    startHour: 18,
                    awayTeam: Team(id: "HH", name: "한화"),
                    homeTeam: Team(id: "SS", name: "삼성")
                ),
                makeGame(
                    id: "scheduled-favorite",
                    status: .scheduled,
                    startHour: 17,
                    awayTeam: Team(id: "LG", name: "LG"),
                    homeTeam: Team(id: "OB", name: "두산")
                ),
                makeGame(
                    id: "final-other",
                    status: .final,
                    startHour: 16,
                    awayTeam: Team(id: "KT", name: "KT"),
                    homeTeam: Team(id: "NC", name: "NC")
                )
            ]
        )

        let orderedIds = todayGames.orderedGames(preferredTeamID: "LG").map(\.id)

        #expect(orderedIds == ["scheduled-favorite", "live-other", "final-other"])
    }

    @Test func teamOptionsUseActualStandingsRanksWhenAvailable() {
        let teams = [
            KboTeamOption(id: "LG", name: "LG"),
            KboTeamOption(id: "OB", name: "두산"),
            KboTeamOption(id: "SK", name: "SSG")
        ]
        let game = makeGame(
            id: "ranked",
            status: .scheduled,
            startHour: 18,
            awayTeam: Team(id: "LG", name: "LG"),
            homeTeam: Team(id: "OB", name: "두산"),
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 10, losses: 5, draws: 0, rank: 3),
                home: TeamRecordSummary(wins: 12, losses: 4, draws: 0, rank: 1)
            )
        )

        let sortedIds = KboTeamOption.sortedByStandings(teams, games: [game]).map(\.id)

        #expect(sortedIds == ["OB", "LG", "SK"])
    }

    @Test func teamOptionsFallBackToTemporaryStandingsOrderWhenRanksAreMissing() {
        let teams = [
            KboTeamOption(id: "LT", name: "롯데"),
            KboTeamOption(id: "HT", name: "KIA"),
            KboTeamOption(id: "LG", name: "LG"),
            KboTeamOption(id: "KT", name: "KT")
        ]

        let sortedIds = KboTeamOption.sortedByStandings(teams, games: []).map(\.id)

        #expect(sortedIds == ["LG", "KT", "HT", "LT"])
    }
}

private func makeGame(
    id: String,
    status: GameStatus,
    startHour: Int,
    awayTeam: Team = Team(id: "LG", name: "LG"),
    homeTeam: Team = Team(id: "OB", name: "두산"),
    teamRecords: TeamRecords? = nil
) -> Game {
    let calendar = Calendar(identifier: .gregorian)
    let startTime = calendar.date(from: DateComponents(
        timeZone: TimeZone(identifier: "Asia/Seoul"),
        year: 2026,
        month: 6,
        day: 10,
        hour: startHour,
        minute: 30
    ))

    return Game(
        id: id,
        date: "20260610",
        venue: "잠실",
        startTime: startTime,
        status: status,
        awayTeam: awayTeam,
        homeTeam: homeTeam,
        score: Score(away: 0, home: 0),
        inning: nil,
        count: nil,
        bases: nil,
        current: nil,
        probablePitchers: ProbablePitchers(away: ProbablePitcher(name: nil), home: ProbablePitcher(name: nil)),
        recentPlay: nil,
        teamRecords: teamRecords,
        sourceMeta: SourceMeta(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
    )
}
