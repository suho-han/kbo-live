import Foundation

public struct LiveGamePollingService: Sendable {
    public let repository: any GameRepository
    public let interval: Duration

    public init(repository: any GameRepository, interval: Duration = .seconds(15)) {
        self.repository = repository
        self.interval = interval
    }

    public func streamTodayGames(date: String? = nil) -> AsyncThrowingStream<TodayGames, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    while Task.isCancelled == false {
                        let games = try await repository.fetchTodayGames(date: date)
                        continuation.yield(games)

                        try await Task.sleep(for: interval)
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
