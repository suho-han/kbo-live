import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

public protocol BaseballLiveKRAPIClient: Sendable {
    func fetchTodayGames(date: String?) async throws -> TodayGamesResponseDTO
    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetailResponseDTO
    func fetchTeamStandings(date: String?) async throws -> TeamStandingsResponseDTO
}

public enum BaseballLiveKRAPIError: Error, Sendable, Equatable {
    case invalidBaseURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case server(statusCode: Int, code: String, message: String)
    case emptyResponse
}

extension BaseballLiveKRAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "백엔드 URL 형식이 올바르지 않습니다."
        case .invalidResponse:
            return "백엔드 서버 응답을 해석할 수 없습니다."
        case let .unexpectedStatusCode(statusCode):
            return "백엔드 서버가 오류 상태를 반환했습니다. HTTP \(statusCode)"
        case let .server(_, _, message):
            return message
        case .emptyResponse:
            return "백엔드 서버 응답이 비어 있습니다."
        }
    }
}

private struct APIErrorResponseDTO: Decodable {
    struct ErrorBody: Decodable {
        let code: String
        let message: String
        let statusCode: Int?
    }

    let error: ErrorBody
}

public struct URLSessionBaseballLiveKRAPIClient: BaseballLiveKRAPIClient, Sendable {
    public let baseURL: URL
    public let apiPathPrefix: String

    private let session: any HTTPSession
    private let decoder: JSONDecoder

    public init(
        baseURL: URL,
        apiPathPrefix: String = BaseballLiveKREnvironment.defaultAPIPathPrefix,
        session: any HTTPSession = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.apiPathPrefix = Self.normalizedPath(apiPathPrefix)
        self.session = session
        self.decoder = decoder
    }

    public func fetchTodayGames(date: String? = nil) async throws -> TodayGamesResponseDTO {
        let request = try makeRequest(path: "/games/today", date: date)
        let data = try await perform(request)
        return try decoder.decode(TodayGamesResponseDTO.self, from: data)
    }

    public func fetchGameDetail(gameId: String, date: String? = nil) async throws -> GameDetailResponseDTO {
        let request = try makeRequest(path: "/games/\(gameId)", date: date)
        let data = try await perform(request)
        return try decoder.decode(GameDetailResponseDTO.self, from: data)
    }

    public func fetchTeamStandings(date: String? = nil) async throws -> TeamStandingsResponseDTO {
        let request = try makeRequest(path: "/standings", date: date)
        let data = try await perform(request)
        return try decoder.decode(TeamStandingsResponseDTO.self, from: data)
    }

    private func makeRequest(path: String, date: String?) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw BaseballLiveKRAPIError.invalidBaseURL
        }

        let normalizedPath = Self.normalizedPath(path)

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let prefix = apiPathPrefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestPath = normalizedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let effectivePrefix = Self.shouldAppendPrefix(prefix, to: basePath) ? prefix : ""
        let pathParts = [basePath, effectivePrefix, requestPath].filter { $0.isEmpty == false }
        components.path = "/" + pathParts.joined(separator: "/")

        if let date, date.isEmpty == false {
            components.queryItems = [
                URLQueryItem(name: "date", value: date)
            ]
        }

        guard let url = components.url else {
            throw BaseballLiveKRAPIError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private static func normalizedPath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard trimmed.isEmpty == false else {
            return ""
        }

        return "/" + trimmed
    }

    private static func shouldAppendPrefix(_ prefix: String, to basePath: String) -> Bool {
        guard prefix.isEmpty == false else {
            return false
        }

        guard basePath.isEmpty == false else {
            return true
        }

        return basePath != prefix && basePath.hasSuffix("/" + prefix) == false
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BaseballLiveKRAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(APIErrorResponseDTO.self, from: data) {
                throw BaseballLiveKRAPIError.server(
                    statusCode: apiError.error.statusCode ?? httpResponse.statusCode,
                    code: apiError.error.code,
                    message: apiError.error.message
                )
            }
            throw BaseballLiveKRAPIError.unexpectedStatusCode(httpResponse.statusCode)
        }

        guard data.isEmpty == false else {
            throw BaseballLiveKRAPIError.emptyResponse
        }

        return data
    }
}
