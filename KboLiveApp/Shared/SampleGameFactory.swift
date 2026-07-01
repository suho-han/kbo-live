import Foundation

enum SampleGameFactory {
    static var todayGames: TodayGames {
        TodayGames(date: sampleDate, games: [currentGame, scheduledGame, finalGame])
    }

    static var representativeGame: Game {
        currentGame
    }

    static var menuBarSummary: MenuBarGameSummary {
        MenuBarGameSummaryMapper.map(representativeGame)
    }

    static var widgetSnapshot: WidgetGameSnapshot {
        favoriteTeamWidgetSnapshot
    }

    static var favoriteTeamWidgetSnapshot: WidgetGameSnapshot {
        WidgetGameSnapshotMapper.map(representativeGame, favoriteTeamID: "KT")
    }

    static var favoriteTeamNoGameWidgetSnapshot: WidgetGameSnapshot {
        WidgetGameSnapshotMapper.map(
            scheduledGame,
            favoriteTeamID: "LG",
            fallbackKind: .favoriteTeamNoGame
        )
    }

    static var noFavoriteTeamSelectedWidgetSnapshot: WidgetGameSnapshot {
        WidgetGameSnapshotMapper.map(
            finalGame,
            fallbackKind: .favoriteTeamNotSelected
        )
    }

    static var activityState: ActivityGameState {
        ActivityGameStateMapper.map(representativeGame)
    }

    private static let sampleDate = "20260614"
    private static let fetchedAt = "2026-06-14T17:42:00.000+09:00"

    private static var currentGame: Game {
        Game(
            id: "20260614NCKT0",
            date: sampleDate,
            venue: "수원",
            startTime: makeStartTime(hour: 17, minute: 0),
            status: .live,
            awayTeam: Team(id: "NC", name: "NC"),
            homeTeam: Team(id: "KT", name: "KT"),
            score: Score(away: 2, home: 1),
            inning: InningState(number: 5, half: .top),
            count: CountState(balls: 1, strikes: 2, outs: 1),
            bases: BasesState(first: true, second: false, third: true),
            current: CurrentMatchup(batter: "박민우", pitcher: "고영표"),
            probablePitchers: ProbablePitchers(
                away: ProbablePitcher(name: "김준원"),
                home: ProbablePitcher(name: "고영표")
            ),
            recentPlay: "5회초 NC 박민우 타석, 1사 1,3루 기회",
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 31, losses: 34, draws: 2, rank: 7, streak: "1패"),
                home: TeamRecordSummary(wins: 39, losses: 25, draws: 2, rank: 2, streak: "2승")
            ),
            boxScore: BoxScore(
                away: TeamBoxScore(runs: 2, hits: 6, errors: 0, walks: 2),
                home: TeamBoxScore(runs: 1, hits: 4, errors: 1, walks: 1),
                linescore: [
                    InningScore(inning: 1, away: 0, home: 0),
                    InningScore(inning: 2, away: 1, home: 0),
                    InningScore(inning: 3, away: 0, home: 1),
                    InningScore(inning: 4, away: 1, home: 0),
                    InningScore(inning: 5, away: nil, home: nil)
                ]
            ),
            lineupPreview: LineupPreview(
                away: ["박민우", "김주원", "데이비슨"],
                home: ["김민혁", "강백호", "문상철"]
            ),
            analysis: TeamAnalysis(
                awaySummary: "NC는 상위 타선 출루로 추가점 기회를 만들고 있습니다.",
                homeSummary: "KT는 고영표의 제구와 내야 수비 안정감이 필요합니다.",
                keyPoints: ["1사 1,3루", "한 점 차 접전", "KT 불펜 대기"]
            ),
            sourceMeta: SourceMeta(rawStatusCode: "1", rawTopBottomCode: "T", fetchedAt: fetchedAt)
        )
    }

    private static var scheduledGame: Game {
        Game(
            id: "20260614HHWO0",
            date: sampleDate,
            venue: "고척",
            startTime: makeStartTime(hour: 19, minute: 30),
            status: .scheduled,
            awayTeam: Team(id: "HH", name: "한화"),
            homeTeam: Team(id: "WO", name: "키움"),
            score: Score(away: 0, home: 0),
            inning: nil,
            count: nil,
            bases: nil,
            current: nil,
            probablePitchers: ProbablePitchers(
                away: ProbablePitcher(
                    name: "왕옌청",
                    record: PitcherSeasonSummary(wins: 5, losses: 4, era: 3.41, whip: 1.18)
                ),
                home: ProbablePitcher(
                    name: "로젠버그",
                    record: PitcherSeasonSummary(wins: 7, losses: 3, era: 2.87, whip: 1.06)
                )
            ),
            recentPlay: nil,
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 34, losses: 31, draws: 1, rank: 5, streak: "1승"),
                home: TeamRecordSummary(wins: 27, losses: 39, draws: 2, rank: 10, streak: "2패")
            ),
            lineupPreview: LineupPreview(
                away: ["문현빈", "페라자", "노시환"],
                home: ["송성문", "이주형", "김혜성"]
            ),
            analysis: TeamAnalysis(
                awaySummary: "한화는 선발 매치업과 중심 타선 장타력이 관전 포인트입니다.",
                homeSummary: "키움은 초반 출루와 불펜 소모 관리가 중요합니다.",
                keyPoints: ["선발 예고", "고척 야간 경기", "상위 타선 출루율"]
            ),
            sourceMeta: SourceMeta(rawStatusCode: "1", rawTopBottomCode: nil, fetchedAt: fetchedAt)
        )
    }

    private static var finalGame: Game {
        Game(
            id: "20260613LTLG0",
            date: "20260613",
            venue: "잠실",
            startTime: makeStartTime(day: 13, hour: 17, minute: 0),
            status: .final,
            awayTeam: Team(id: "LT", name: "롯데"),
            homeTeam: Team(id: "LG", name: "LG"),
            score: Score(away: 3, home: 5),
            inning: InningState(number: 9, half: .top),
            count: CountState(balls: 0, strikes: 0, outs: 3),
            bases: BasesState(first: false, second: false, third: false),
            current: nil,
            probablePitchers: ProbablePitchers(
                away: ProbablePitcher(name: "비슬리"),
                home: ProbablePitcher(name: "임찬규")
            ),
            recentPlay: "LG가 8회 추가점으로 리드를 지키며 경기를 마쳤습니다.",
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 30, losses: 34, draws: 1, rank: 8, streak: "1패"),
                home: TeamRecordSummary(wins: 37, losses: 27, draws: 1, rank: 1, streak: "1승")
            ),
            boxScore: BoxScore(
                away: TeamBoxScore(runs: 3, hits: 9, errors: 1, walks: 2),
                home: TeamBoxScore(runs: 5, hits: 10, errors: 0, walks: 5),
                linescore: [
                    InningScore(inning: 1, away: 0, home: 1),
                    InningScore(inning: 2, away: 2, home: 0),
                    InningScore(inning: 3, away: 0, home: 0),
                    InningScore(inning: 4, away: 0, home: 2),
                    InningScore(inning: 5, away: 1, home: 0),
                    InningScore(inning: 6, away: 0, home: 1),
                    InningScore(inning: 7, away: 0, home: 0),
                    InningScore(inning: 8, away: 0, home: 1),
                    InningScore(inning: 9, away: 0, home: nil)
                ]
            ),
            analysis: TeamAnalysis(
                awaySummary: "롯데는 중반 이후 추가 득점 연결이 부족했습니다.",
                homeSummary: "LG는 후반 집중타와 불펜 운영으로 리드를 지켰습니다.",
                keyPoints: ["LG 8회 추가점", "롯데 잔루 7개", "홈팀 무실책"]
            ),
            sourceMeta: SourceMeta(rawStatusCode: "3", rawTopBottomCode: "T", fetchedAt: fetchedAt)
        )
    }

    private static func makeStartTime(hour: Int, minute: Int) -> Date? {
        makeStartTime(day: 14, hour: hour, minute: minute)
    }

    private static func makeStartTime(day: Int, hour: Int, minute: Int) -> Date? {
        Calendar(identifier: .gregorian).date(from: DateComponents(
            timeZone: TimeZone(identifier: "Asia/Seoul"),
            year: 2026,
            month: 6,
            day: day,
            hour: hour,
            minute: minute
        ))
    }
}
