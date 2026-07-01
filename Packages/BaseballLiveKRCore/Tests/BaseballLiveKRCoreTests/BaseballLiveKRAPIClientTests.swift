import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import BaseballLiveKRCore

struct BaseballLiveKRAPIClientTests {
    @Test func fetchTodayGamesBuildsExpectedRequestAndDecodesResponse() async throws {
        let session = TestHTTPSession { request in
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.url?.absoluteString == "http://localhost:3000/v1/games/today?date=2026-06-10")

            let data = try FixtureLoader.loadData(named: "today-games-response")
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: try #require(URL(string: "http://localhost:3000")),
            session: session
        )

        let response = try await client.fetchTodayGames(date: "2026-06-10")

        #expect(response.date == "20260610")
        #expect(response.games.count == 2)
    }

    @Test func fetchTodayGamesAllowsUnversionedCompatibilityPath() async throws {
        let session = TestHTTPSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/games/today?date=2026-06-10")

            let data = try FixtureLoader.loadData(named: "today-games-response")
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: try #require(URL(string: "http://localhost:3000")),
            apiPathPrefix: "",
            session: session
        )

        let response = try await client.fetchTodayGames(date: "2026-06-10")

        #expect(response.date == "20260610")
    }

    @Test func fetchTodayGamesDoesNotDuplicateVersionPrefixAlreadyInBaseURL() async throws {
        let session = TestHTTPSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/v1/games/today?date=2026-06-10")

            let data = try FixtureLoader.loadData(named: "today-games-response")
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: try #require(URL(string: "http://localhost:3000/v1")),
            session: session
        )

        let response = try await client.fetchTodayGames(date: "2026-06-10")

        #expect(response.date == "20260610")
    }

    @Test func fetchTodayGamesDoesNotDuplicateNestedVersionPrefixAlreadyInBaseURL() async throws {
        let session = TestHTTPSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/games/today?date=2026-06-10")

            let data = try FixtureLoader.loadData(named: "today-games-response")
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: try #require(URL(string: "http://localhost:3000/api/v1")),
            apiPathPrefix: "/api/v1",
            session: session
        )

        let response = try await client.fetchTodayGames(date: "2026-06-10")

        #expect(response.date == "20260610")
    }

    @Test func fetchGameDetailUsesGameSpecificPath() async throws {
        let body = """
        {
          "date": "20260610",
          "game": {
            "gameId": "20260610SKLG0",
            "date": "20260610",
            "venue": "잠실",
            "startTime": "2026-06-10T18:30:00+09:00",
            "status": "scheduled",
            "awayTeam": { "id": "SK", "name": "SSG" },
            "homeTeam": { "id": "LG", "name": "LG" },
            "score": { "away": 0, "home": 0 },
            "inning": null,
            "count": null,
            "bases": null,
            "current": null,
            "probablePitchers": { "away": null, "home": null },
            "recentPlay": null,
            "sourceMeta": {
              "rawStatusCode": null,
              "rawTopBottomCode": null,
              "fetchedAt": "2026-06-10T10:05:00.000Z"
            }
          }
        }
        """

        let session = TestHTTPSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/v1/games/20260610SKLG0?date=2026-06-10")

            let data = Data(body.utf8)
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: try #require(URL(string: "http://localhost:3000")),
            session: session
        )

        let response = try await client.fetchGameDetail(gameId: "20260610SKLG0", date: "2026-06-10")

        #expect(response.game?.gameId == "20260610SKLG0")
    }

    @Test func fetchTeamStandingsUsesStandingsPath() async throws {
        let session = TestHTTPSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/v1/standings?date=2026-06-10")

            let data = try FixtureLoader.loadData(named: "team-standings-response")
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: try #require(URL(string: "http://localhost:3000")),
            session: session
        )

        let response = try await client.fetchTeamStandings(date: "2026-06-10")

        #expect(response.date == "20260610")
        #expect(response.standings.first?.teamId == "LG")
    }

    @Test func throwsOnUnexpectedStatusCode() async {
        let session = TestHTTPSession { request in
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (Data("{}".utf8), response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: URL(string: "http://localhost:3000")!,
            session: session
        )

        await #expect(throws: BaseballLiveKRAPIError.unexpectedStatusCode(503)) {
            _ = try await client.fetchTodayGames(date: nil)
        }
    }

    @Test func decodesNormalizedServerErrorResponse() async {
        let body = """
        {
          "error": {
            "code": "INVALID_DATE",
            "message": "invalid date format: 2026",
            "statusCode": 400
          }
        }
        """
        let session = TestHTTPSession { request in
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 400, httpVersion: nil, headerFields: nil)!
            return (Data(body.utf8), response)
        }

        let client = URLSessionBaseballLiveKRAPIClient(
            baseURL: URL(string: "http://localhost:3000")!,
            session: session
        )

        await #expect(throws: BaseballLiveKRAPIError.server(
            statusCode: 400,
            code: "INVALID_DATE",
            message: "invalid date format: 2026"
        )) {
            _ = try await client.fetchTodayGames(date: "2026")
        }
    }
}

private struct TestHTTPSession: HTTPSession, Sendable {
    let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    init(handler: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}
