import Foundation

enum SampleGameFactory {
    static var todayGames: TodayGames {
        TodayGames(date: sampleDate, games: games)
    }

    static var representativeGame: Game {
        todayGames.orderedGames().first ?? games[0]
    }

    static var menuBarSummary: MenuBarGameSummary {
        MenuBarGameSummaryMapper.map(representativeGame)
    }

    static var widgetSnapshot: WidgetGameSnapshot {
        WidgetGameSnapshotMapper.map(representativeGame)
    }

    static var activityState: ActivityGameState {
        ActivityGameStateMapper.map(representativeGame)
    }

    private static let sampleDate = "20260613"
    private static let fetchedAt = "2026-06-13T15:43:19.698Z"

    private static var games: [Game] {
        [
            liveLGVsSamsung,
            scheduledKiaVsHanwha,
            lgtwinsVsLotte,
            samsungVsSSG,
            kiaVsDoosan,
            ktVsNC,
            kiwoomVsHanwha
        ]
    }

    private static var liveLGVsSamsung: Game {
        Game(
            id: "20260613LGSS1",
            date: sampleDate,
            venue: "잠실",
            startTime: makeStartTime(hour: 18, minute: 30),
            status: .live,
            awayTeam: Team(id: "SS", name: "삼성"),
            homeTeam: Team(id: "LG", name: "LG"),
            score: Score(away: 4, home: 3),
            inning: InningState(number: 6, half: .bottom),
            count: CountState(balls: 2, strikes: 1, outs: 1),
            bases: BasesState(first: true, second: true, third: false),
            current: CurrentMatchup(batter: "문보경", pitcher: "원태인"),
            probablePitchers: ProbablePitchers(away: "원태인", home: "임찬규"),
            recentPlay: "6회말 LG 문보경, 우전 안타로 1사 1,2루 기회",
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 34, losses: 29, draws: 2, rank: 4, streak: "2승"),
                home: TeamRecordSummary(wins: 36, losses: 27, draws: 1, rank: 2, streak: "1패")
            ),
            boxScore: BoxScore(
                away: TeamBoxScore(runs: 4, hits: 8, errors: 1, walks: 3),
                home: TeamBoxScore(runs: 3, hits: 7, errors: 0, walks: 4),
                linescore: [
                    InningScore(inning: 1, away: 1, home: 0),
                    InningScore(inning: 2, away: 0, home: 1),
                    InningScore(inning: 3, away: 2, home: 0),
                    InningScore(inning: 4, away: 0, home: 0),
                    InningScore(inning: 5, away: 1, home: 1),
                    InningScore(inning: 6, away: nil, home: 1)
                ]
            ),
            lineupPreview: LineupPreview(
                away: ["김지찬", "구자욱", "디아즈"],
                home: ["홍창기", "문성주", "오스틴"]
            ),
            analysis: TeamAnalysis(
                awaySummary: "삼성은 중심 타선 장타력으로 리드를 지키는 흐름입니다.",
                homeSummary: "LG는 하위 타선 출루 뒤 상위 타선 연결이 관건입니다.",
                keyPoints: ["1사 1,2루 득점권", "LG 불펜 대기", "삼성 외야 수비 전진"]
            ),
            sourceMeta: SourceMeta(rawStatusCode: "1", rawTopBottomCode: "B", fetchedAt: fetchedAt)
        )
    }

    private static var scheduledKiaVsHanwha: Game {
        Game(
            id: "20260613HHHT1",
            date: sampleDate,
            venue: "광주",
            startTime: makeStartTime(hour: 19, minute: 0),
            status: .scheduled,
            awayTeam: Team(id: "HH", name: "한화"),
            homeTeam: Team(id: "HT", name: "KIA"),
            score: Score(away: 0, home: 0),
            inning: nil,
            count: nil,
            bases: nil,
            current: nil,
            probablePitchers: ProbablePitchers(away: "류현진", home: "네일"),
            recentPlay: nil,
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 33, losses: 30, draws: 1, rank: 5, streak: "1승"),
                home: TeamRecordSummary(wins: 38, losses: 25, draws: 2, rank: 1, streak: "3승")
            ),
            lineupPreview: LineupPreview(
                away: ["문현빈", "페라자", "노시환"],
                home: ["박찬호", "김도영", "최형우"]
            ),
            analysis: TeamAnalysis(
                awaySummary: "한화는 류현진의 초반 제구와 중심 타선 한 방이 변수입니다.",
                homeSummary: "KIA는 홈 경기 흐름과 상위 타선 출루율이 강점입니다.",
                keyPoints: ["좌완 선발 매치업", "광주 홈 응원 분위기", "초반 3이닝 실점 억제"]
            ),
            sourceMeta: SourceMeta(rawStatusCode: "0", rawTopBottomCode: nil, fetchedAt: fetchedAt)
        )
    }

    private static var lgtwinsVsLotte: Game {
        Game(
            id: "20260613LTLG0",
            date: sampleDate,
            venue: "잠실",
            startTime: makeStartTime(hour: 17, minute: 0),
            status: .final,
            awayTeam: Team(id: "LT", name: "롯데"),
            homeTeam: Team(id: "LG", name: "LG"),
            score: Score(away: 3, home: 5),
            inning: InningState(number: 9, half: .top),
            count: CountState(balls: 3, strikes: 1, outs: 3),
            bases: BasesState(first: true, second: false, third: false),
            current: CurrentMatchup(batter: "유강남", pitcher: "손주영"),
            probablePitchers: ProbablePitchers(away: "이민석", home: "김진수"),
            recentPlay: nil,
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 30, losses: 34, draws: 1, rank: 7, streak: "1패"),
                home: TeamRecordSummary(wins: 36, losses: 27, draws: 1, rank: 2, streak: "1승")
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
                awaySummary: "롯데는 중반 이후 추가점을 만들지 못했습니다.",
                homeSummary: "LG는 불펜 운영과 후반 집중타로 경기를 가져왔습니다.",
                keyPoints: ["LG 8회 추가점", "롯데 잔루 7개", "홈팀 무실책"]
            ),
            sourceMeta: SourceMeta(rawStatusCode: "3", rawTopBottomCode: "T", fetchedAt: fetchedAt)
        )
    }

    private static var samsungVsSSG: Game {
        Game(
            id: "20260613SKSS0",
            date: sampleDate,
            venue: "대구",
            startTime: makeStartTime(hour: 17, minute: 0),
            status: .final,
            awayTeam: Team(id: "SK", name: "SSG"),
            homeTeam: Team(id: "SS", name: "삼성"),
            score: Score(away: 6, home: 7),
            inning: InningState(number: 9, half: .top),
            count: CountState(balls: 0, strikes: 0, outs: 3),
            bases: BasesState(first: false, second: false, third: false),
            current: CurrentMatchup(batter: "에레디아", pitcher: "김재윤"),
            probablePitchers: ProbablePitchers(away: "베니지아노", home: "후라도"),
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: "3", rawTopBottomCode: "T", fetchedAt: fetchedAt)
        )
    }

    private static var kiaVsDoosan: Game {
        Game(
            id: "20260613OBHT0",
            date: sampleDate,
            venue: "광주",
            startTime: makeStartTime(hour: 17, minute: 0),
            status: .final,
            awayTeam: Team(id: "OB", name: "두산"),
            homeTeam: Team(id: "HT", name: "KIA"),
            score: Score(away: 1, home: 2),
            inning: InningState(number: 9, half: .top),
            count: CountState(balls: 1, strikes: 3, outs: 3),
            bases: BasesState(first: false, second: false, third: false),
            current: CurrentMatchup(batter: "이유찬", pitcher: "성영탁"),
            probablePitchers: ProbablePitchers(away: "벤자민", home: "네일"),
            recentPlay: nil,
            teamRecords: TeamRecords(
                away: TeamRecordSummary(wins: 31, losses: 33, draws: 1, rank: 6, streak: "2패"),
                home: TeamRecordSummary(wins: 38, losses: 25, draws: 2, rank: 1, streak: "3승")
            ),
            boxScore: BoxScore(
                away: TeamBoxScore(runs: 1, hits: 5, errors: 0, walks: 3),
                home: TeamBoxScore(runs: 2, hits: 7, errors: 0, walks: 2),
                linescore: [
                    InningScore(inning: 1, away: 0, home: 0),
                    InningScore(inning: 2, away: 0, home: 1),
                    InningScore(inning: 3, away: 0, home: 0),
                    InningScore(inning: 4, away: 1, home: 0),
                    InningScore(inning: 5, away: 0, home: 0),
                    InningScore(inning: 6, away: 0, home: 1),
                    InningScore(inning: 7, away: 0, home: 0),
                    InningScore(inning: 8, away: 0, home: 0),
                    InningScore(inning: 9, away: 0, home: nil)
                ]
            ),
            analysis: TeamAnalysis(
                awaySummary: "두산은 득점권 한 방이 부족했습니다.",
                homeSummary: "KIA는 선발 이후 불펜이 1점 차를 지켰습니다.",
                keyPoints: ["KIA 6회 결승점", "두 팀 무실책", "광주 저득점 접전"]
            ),
            sourceMeta: SourceMeta(rawStatusCode: "3", rawTopBottomCode: "T", fetchedAt: fetchedAt)
        )
    }

    private static var ktVsNC: Game {
        Game(
            id: "20260613NCKT0",
            date: sampleDate,
            venue: "수원",
            startTime: makeStartTime(hour: 17, minute: 0),
            status: .final,
            awayTeam: Team(id: "NC", name: "NC"),
            homeTeam: Team(id: "KT", name: "KT"),
            score: Score(away: 9, home: 11),
            inning: InningState(number: 9, half: .top),
            count: CountState(balls: 1, strikes: 0, outs: 3),
            bases: BasesState(first: false, second: true, third: false),
            current: CurrentMatchup(batter: "도태훈", pitcher: "박영현"),
            probablePitchers: ProbablePitchers(away: "토다", home: "오원석"),
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: "3", rawTopBottomCode: "T", fetchedAt: fetchedAt)
        )
    }

    private static var kiwoomVsHanwha: Game {
        Game(
            id: "20260613HHWO0",
            date: sampleDate,
            venue: "고척",
            startTime: makeStartTime(hour: 17, minute: 0),
            status: .final,
            awayTeam: Team(id: "HH", name: "한화"),
            homeTeam: Team(id: "WO", name: "키움"),
            score: Score(away: 1, home: 3),
            inning: InningState(number: 9, half: .top),
            count: CountState(balls: 2, strikes: 3, outs: 3),
            bases: BasesState(first: true, second: false, third: false),
            current: CurrentMatchup(batter: "박정현", pitcher: "유토"),
            probablePitchers: ProbablePitchers(away: "박준영", home: "알칸타라"),
            recentPlay: nil,
            sourceMeta: SourceMeta(rawStatusCode: "3", rawTopBottomCode: "T", fetchedAt: fetchedAt)
        )
    }

    private static func makeStartTime(hour: Int, minute: Int) -> Date? {
        Calendar(identifier: .gregorian).date(from: DateComponents(
            timeZone: TimeZone(identifier: "Asia/Seoul"),
            year: 2026,
            month: 6,
            day: 13,
            hour: hour,
            minute: minute
        ))
    }
}
