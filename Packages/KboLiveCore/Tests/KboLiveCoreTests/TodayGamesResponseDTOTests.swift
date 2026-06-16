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
        #expect(mapped.probablePitchers.away == nil)
        #expect(mapped.probablePitchers.home == nil)
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

    @Test func mapsOptionalDetailFieldsIntoDomain() {
        let dto = GameDTO(
            gameId: "detail-rich",
            date: "20260610",
            venue: "잠실",
            startTime: "2026-06-10T18:30:00+09:00",
            status: .live,
            awayTeam: TeamDTO(id: "SS", name: "삼성"),
            homeTeam: TeamDTO(id: "LG", name: "LG"),
            score: ScoreDTO(away: 4, home: 3),
            inning: InningDTO(number: 6, half: .bottom),
            count: CountDTO(balls: 2, strikes: 1, outs: 1),
            bases: BasesDTO(first: true, second: true, third: false),
            current: CurrentMatchupDTO(batter: "문보경", pitcher: "원태인"),
            probablePitchers: ProbablePitchersDTO(away: "원태인", home: "임찬규"),
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
        #expect(mapped.boxScore?.away.hits == 8)
        #expect(mapped.boxScore?.linescore.first?.home == 0)
        #expect(mapped.lineupPreview?.home == ["홍창기"])
        #expect(mapped.analysis?.keyPoints == ["득점권"])
    }
}
