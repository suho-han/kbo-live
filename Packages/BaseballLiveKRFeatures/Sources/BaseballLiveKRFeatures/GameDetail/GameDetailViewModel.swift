import Foundation
import Combine
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif

@MainActor
public final class GameDetailViewModel: ObservableObject {
    public enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(message: String)
    }

    public let gameID: String
    public let requestDate: String?

    @Published public private(set) var state: State
    @Published public private(set) var game: Game?
    @Published public private(set) var lastUpdatedAt: Date?

    private let client: GameFeedClient
    private let now: @Sendable () -> Date

    public init(
        client: GameFeedClient,
        gameID: String,
        requestDate: String?,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.client = client
        self.gameID = gameID
        self.requestDate = requestDate
        self.now = now
        self.state = .idle
        self.game = nil
        self.lastUpdatedAt = nil
    }

    public var isLoading: Bool {
        state == .loading
    }

    public func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    public func load() async {
        if game == nil {
            state = .loading
        }

        do {
            let response = try await client.fetchGameDetail(gameId: gameID, date: requestDate)
            game = response.game
            lastUpdatedAt = now()
            state = .loaded
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    public func refresh() async {
        await load()
    }

    private static func message(for error: Error) -> String {
        if error is URLError {
            return "백엔드 서버에 연결할 수 없습니다. 설정에서 Backend URL을 확인해 주세요."
        }

        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           description.isEmpty == false {
            return description
        }

        return "경기 상세 데이터를 불러오지 못했습니다."
    }
}
