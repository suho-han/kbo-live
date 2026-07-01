import Foundation
import Testing
@testable import KboLiveCore

struct TodayGamesResponseDTOTests {
    @Test func decodesTodayGamesFixture() throws {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)

        #expect(decoded.date == "20260610")
        #expect(decoded.games.count == 2)
        #expect(decoded.games.first?.gameId == "20260610SKLG0")
        #expect(decoded.games.first?.awayTeam.name == "SSG")
        #expect(decoded.games.first?.homeTeam.name == "LG")
        #expect(decoded.games.first?.status == .scheduled)
    }

    @Test func mapsBlankStringsToNilInDomain() throws {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
        let game = try #require(decoded.games.first)
        let mapped = GameDTOMapper.map(game)

        #expect(mapped.current?.batter == nil)
        #expect(mapped.current?.pitcher == nil)
        #expect(mapped.probablePitchers.away.name == nil)
        #expect(mapped.probablePitchers.home.name == nil)
    }

    @Test func parsesIsoStartTimeIntoDate() throws {
        let data = try FixtureLoader.loadData(named: "today-games-response")
        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
        let game = decoded.games[1]
        let mapped = GameDTOMapper.map(game)

        #expect(mapped.startTime != nil)
        #expect(mapped.status == .live)
        #expect(mapped.inning?.number == 7)
        #expect(mapped.inning?.half == .bottom)
        #expect(mapped.broadcastChannels == ["KBSN"])
        #expect(mapped.homepageLinks?.review?.contains("section=REVIEW") == true)
        #expect(mapped.pitcherDecisions?.save == "정해영")
        #expect(mapped.probablePitchers.home.record == PitcherSeasonSummary(wins: 5, losses: 4, era: 3.22, whip: 1.17))
    }

    @Test func decodesBackendLiveContractFixture() throws {
        let data = try FixtureLoader.loadData(named: "live-test-game-response")
        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
        let game = try #require(decoded.games.first)
        let mapped = GameDTOMapper.map(game)

        #expect(decoded.date == "20260615")
        #expect(mapped.id == "20260615LTHH0")
        #expect(mapped.status == .live)
        #expect(mapped.score.away == 12)
        #expect(mapped.score.home == 9)
        #expect(mapped.inning?.number == 7)
        #expect(mapped.inning?.half == .bottom)
        #expect(mapped.bases?.first == true)
        #expect(mapped.bases?.second == true)
        #expect(mapped.bases?.third == false)
        #expect(mapped.current?.batter == "노시환")
        #expect(mapped.probablePitchers.away.name == "반즈")
        #expect(mapped.probablePitchers.home.name == "문동주")
        #expect(mapped.teamRecords?.home?.rank == 3)
        #expect(mapped.boxScore?.away.runs == 12)
        #expect(mapped.recentPlay == "7회말 한화 공격, 1사 1,2루에서 노시환 타석")
    }

    @Test func parsesExtendedIsoStartTimeIntoDate() {
        let dto = GameDTO(
            gameId: "extended-iso",
            date: "20260610",
            venue: "잠실",
            startTime: "2026-06-10T18:30:00+09:00",
            status: .scheduled,
            awayTeam: TeamDTO(id: "LG", name: "LG"),
            homeTeam: TeamDTO(id: "OB", name: "두산"),
            score: ScoreDTO(away: 0, home: 0),
            inning: nil,
            count: nil,
            bases: nil,
            current: nil,
            probablePitchers: ProbablePitchersDTO(away: nil, home: nil),
            recentPlay: nil,
            sourceMeta: SourceMetaDTO(rawStatusCode: nil, rawTopBottomCode: nil, fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        let mapped = GameDTOMapper.map(dto)

        #expect(mapped.startTime != nil)
    }

    @Test func mapsPregameLiveLikeResponseToScheduledBeforeStartTime() {
        let dto = GameDTO(
            gameId: "20260618LGHT0",
            date: "20260618",
            venue: "광주",
            startTime: "20260618T18:30:00+09:00",
            status: .live,
            awayTeam: TeamDTO(id: "LG", name: "LG"),
            homeTeam: TeamDTO(id: "HT", name: "KIA"),
            score: ScoreDTO(away: 0, home: 0),
            inning: InningDTO(number: 1, half: .top),
            count: CountDTO(balls: 0, strikes: 0, outs: 0),
            bases: BasesDTO(first: false, second: false, third: false),
            current: CurrentMatchupDTO(batter: "홍창기", pitcher: "양현종"),
            probablePitchers: ProbablePitchersDTO(
                away: ProbablePitcherDTO(name: "톨허스트"),
                home: ProbablePitcherDTO(name: "양현종")
            ),
            recentPlay: "1회초 홍창기 타석, 투수 양현종, 카운트 0-0, 0아웃, 주자 없음",
            sourceMeta: SourceMetaDTO(rawStatusCode: "1", rawTopBottomCode: "T", fetchedAt: "2026-06-18T08:56:50.000Z")
        )

        let mapped = GameDTOMapper.map(dto, now: Date(timeIntervalSince1970: 1_781_773_010))

        #expect(mapped.status == .scheduled)
        #expect(mapped.inning == nil)
        #expect(mapped.count == nil)
        #expect(mapped.bases == nil)
        #expect(mapped.current == nil)
        #expect(mapped.recentPlay == nil)
        #expect(mapped.probablePitchers.home.name == "양현종")
    }

    @Test func keepsBackendProvidedCurrentMatchupAuthoritative() {
        let dto = GameDTO(
            gameId: "20260618LGHT0",
            date: "20260618",
            venue: "광주",
            startTime: "20260618T18:30:00+09:00",
            status: .live,
            awayTeam: TeamDTO(id: "LG", name: "LG"),
            homeTeam: TeamDTO(id: "HT", name: "KIA"),
            score: ScoreDTO(away: 1, home: 0),
            inning: InningDTO(number: 2, half: .bottom),
            count: CountDTO(balls: 0, strikes: 0, outs: 2),
            bases: BasesDTO(first: false, second: false, third: false),
            current: CurrentMatchupDTO(batter: "시라카와", pitcher: "김규성"),
            probablePitchers: ProbablePitchersDTO(
                away: ProbablePitcherDTO(name: "톨허스트"),
                home: ProbablePitcherDTO(name: "양현종")
            ),
            recentPlay: "김규성 : 우익수 앞 1루타",
            sourceMeta: SourceMetaDTO(rawStatusCode: "1", rawTopBottomCode: "B", fetchedAt: "2026-06-18T10:09:28.000Z")
        )

        let mapped = GameDTOMapper.map(dto)

        #expect(mapped.current?.batter == "시라카와")
        #expect(mapped.current?.pitcher == "김규성")
        #expect(mapped.recentPlay == "김규성 : 우익수 앞 1루타")
    }

    @Test func keepsTopHalfCurrentMatchupWhenPitcherAndBatterAreAlreadyCorrect() {
        let dto = GameDTO(
            gameId: "20260618KTWO0",
            date: "20260618",
            venue: "잠실",
            startTime: "20260618T18:30:00+09:00",
            status: .live,
            awayTeam: TeamDTO(id: "KT", name: "KT"),
            homeTeam: TeamDTO(id: "OB", name: "두산"),
            score: ScoreDTO(away: 0, home: 0),
            inning: InningDTO(number: 3, half: .top),
            count: CountDTO(balls: 0, strikes: 2, outs: 2),
            bases: BasesDTO(first: false, second: true, third: true),
            current: CurrentMatchupDTO(batter: "힐리어드", pitcher: "최민석"),
            probablePitchers: ProbablePitchersDTO(
                away: ProbablePitcherDTO(name: "소형준"),
                home: ProbablePitcherDTO(name: "최민석")
            ),
            recentPlay: "3회초 힐리어드 타석, 투수 최민석, 카운트 0-2, 2아웃, 2,3루",
            sourceMeta: SourceMetaDTO(rawStatusCode: "1", rawTopBottomCode: "T", fetchedAt: "2026-06-18T10:09:28.000Z")
        )

        let mapped = GameDTOMapper.map(dto)

        #expect(mapped.current?.batter == "힐리어드")
        #expect(mapped.current?.pitcher == "최민석")
        #expect(mapped.recentPlay == "3회초 힐리어드 타석, 투수 최민석, 카운트 0-2, 2아웃, 2,3루")
    }

    @Test func mapsOptionalDetailFieldsIntoDomain() {
        let dto = GameDTO(
            gameId: "detail-rich",
            date: "20260610",
            venue: "잠실",
            startTime: "2026-06-10T18:30:00+09:00",
            broadcastChannels: ["SPO-2T"],
            homepageLinks: HomepageLinksDTO(gameCenter: "https://example.test/game", preview: nil, review: nil, highlight: nil),
            pitcherDecisions: PitcherDecisionsDTO(win: "임찬규", loss: "원태인", save: "유영찬"),
            status: .live,
            awayTeam: TeamDTO(id: "SS", name: "삼성"),
            homeTeam: TeamDTO(id: "LG", name: "LG"),
            score: ScoreDTO(away: 4, home: 3),
            inning: InningDTO(number: 6, half: .bottom),
            count: CountDTO(balls: 2, strikes: 1, outs: 1),
            bases: BasesDTO(first: true, second: true, third: false),
            current: CurrentMatchupDTO(batter: "문보경", pitcher: "원태인"),
            probablePitchers: ProbablePitchersDTO(
                away: ProbablePitcherDTO(name: "원태인"),
                home: ProbablePitcherDTO(name: "임찬규")
            ),
            recentPlay: "우전 안타",
            teamRecords: TeamRecordsDTO(
                away: TeamRecordSummaryDTO(wins: 34, losses: 29, draws: 2, rank: 4, streak: "2승"),
                home: TeamRecordSummaryDTO(wins: 36, losses: 27, draws: 1, rank: 2, streak: "1패")
            ),
            boxScore: BoxScoreDTO(
                away: TeamBoxScoreDTO(runs: 4, hits: 8, errors: 1, walks: 3),
                home: TeamBoxScoreDTO(runs: 3, hits: 7, errors: 0, walks: 4),
                linescore: [InningScoreDTO(inning: 1, away: 1, home: 0)]
            ),
            lineupPreview: LineupPreviewDTO(away: ["김지찬"], home: ["홍창기"]),
            analysis: TeamAnalysisDTO(awaySummary: "원정 흐름", homeSummary: "홈 흐름", keyPoints: ["득점권"]),
            sourceMeta: SourceMetaDTO(rawStatusCode: "1", rawTopBottomCode: "B", fetchedAt: "2026-06-10T10:05:00.000Z")
        )

        let mapped = GameDTOMapper.map(dto)

        #expect(mapped.teamRecords?.away?.rank == 4)
        #expect(mapped.broadcastChannels == ["SPO-2T"])
        #expect(mapped.homepageLinks?.gameCenter == "https://example.test/game")
        #expect(mapped.pitcherDecisions?.win == "임찬규")
        #expect(mapped.boxScore?.away.hits == 8)
        #expect(mapped.boxScore?.linescore.first?.home == 0)
        #expect(mapped.lineupPreview?.home == ["홍창기"])
        #expect(mapped.analysis?.keyPoints == ["득점권"])
    }

    @Test func decodesLegacyStringProbablePitchersAndStructuredRecordPayload() throws {
        let data = """
        {
          "date": "20260630",
          "games": [{
            "gameId": "20260630SKHT0",
            "date": "20260630",
            "venue": "광주",
            "startTime": "20260630T18:30:00+09:00",
            "broadcastChannels": ["MS-T"],
            "homepageLinks": null,
            "pitcherDecisions": null,
            "status": "scheduled",
            "awayTeam": { "id": "SK", "name": "SSG" },
            "homeTeam": { "id": "HT", "name": "KIA" },
            "score": { "away": 0, "home": 0 },
            "inning": null,
            "count": null,
            "bases": null,
            "current": null,
            "probablePitchers": {
              "away": "김건우",
              "home": {
                "name": "올러",
                "record": { "wins": 7, "losses": 5, "era": 2.58, "whip": 0.95 }
              }
            },
            "recentPlay": null,
            "sourceMeta": {
              "rawStatusCode": null,
              "rawTopBottomCode": null,
              "fetchedAt": "2026-06-29T00:00:00.000Z"
            }
          }]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
        let mapped = GameDTOMapper.map(try #require(decoded.games.first))

        #expect(mapped.probablePitchers.away.name == "김건우")
        #expect(mapped.probablePitchers.away.record == nil)
        #expect(mapped.probablePitchers.home.record == PitcherSeasonSummary(wins: 7, losses: 5, era: 2.58, whip: 0.95))
    }

    @Test func decodesAndMapsStarterStatusWhenBackendProvidesIt() throws {
        let data = """
        {
          "date": "20260702",
          "games": [{
            "gameId": "20260702LGSS0",
            "date": "20260702",
            "venue": "대구",
            "startTime": "20260702T18:30:00+09:00",
            "status": "scheduled",
            "starterStatus": "missing",
            "awayTeam": { "id": "LG", "name": "LG" },
            "homeTeam": { "id": "SS", "name": "삼성" },
            "score": { "away": 0, "home": 0 },
            "inning": null,
            "count": null,
            "bases": null,
            "current": null,
            "probablePitchers": {
              "away": { "name": null, "record": null },
              "home": { "name": null, "record": null }
            },
            "recentPlay": null,
            "sourceMeta": {
              "rawStatusCode": "1",
              "rawTopBottomCode": null,
              "fetchedAt": "2026-07-01T00:00:00.000Z"
            }
          }]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(TodayGamesResponseDTO.self, from: data)
        let dto = try #require(decoded.games.first)
        let mapped = GameDTOMapper.map(dto)

        #expect(dto.starterStatus == .missing)
        #expect(mapped.starterStatus == .missing)
    }
}
