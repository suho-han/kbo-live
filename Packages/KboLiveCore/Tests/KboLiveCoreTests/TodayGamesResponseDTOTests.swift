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
        let game = try #require(decoded.games[1])
        let mapped = GameDTOMapper.map(game)

        #expect(mapped.startTime != nil)
        #expect(mapped.status == .live)
        #expect(mapped.inning?.number == 7)
        #expect(mapped.inning?.half == .bottom)
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
}
