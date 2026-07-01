import Combine
import Foundation
#if os(iOS) && canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif

@MainActor
final class LiveGameActivityController: ObservableObject {
    @Published private(set) var activeGameID: String?

    init() {
        activeGameID = Self.currentActiveGameID()
    }

    func isActive(gameID: String) -> Bool {
        activeGameID == gameID
    }

    func canStart(game: Game) -> Bool {
#if os(iOS) && canImport(ActivityKit)
        game.status == .live
#else
        false
#endif
    }

    func toggle(for game: Game) async {
        if isActive(gameID: game.id) {
            await stop(gameID: game.id)
        } else {
            await start(for: game)
        }
    }

    func update(with games: [Game]) async {
#if os(iOS) && canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            activeGameID = nil
            return
        }

        activeGameID = await Self.updateActivities(with: games)
#endif
    }

    private func start(for game: Game) async {
#if os(iOS) && canImport(ActivityKit)
        guard game.status == .live else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        activeGameID = await Self.requestActivity(for: game)
#endif
    }

    private func stop(gameID: String) async {
#if os(iOS) && canImport(ActivityKit)
        activeGameID = await Self.endActivity(gameID: gameID)
#endif
    }

#if os(iOS) && canImport(ActivityKit)
    nonisolated private static func requestActivity(for game: Game) async -> String? {
        let attributes = LiveGameActivityAttributes(
            gameID: game.id,
            awayTeamName: game.awayTeam.name,
            homeTeamName: game.homeTeam.name
        )
        let content = LiveGameActivityAttributes.ContentState(
            state: ActivityGameStateMapper.map(game)
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: content, staleDate: staleDate()),
                pushType: nil
            )
        } catch {
            return currentActiveGameID()
        }

        return currentActiveGameID()
    }

    nonisolated private static func endActivity(gameID: String) async -> String? {
        for activity in Activity<LiveGameActivityAttributes>.activities where activity.attributes.gameID == gameID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        return currentActiveGameID()
    }

    nonisolated private static func updateActivities(with games: [Game]) async -> String? {
        let gamesByID = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0) })

        for activity in Activity<LiveGameActivityAttributes>.activities {
            guard let game = gamesByID[activity.attributes.gameID] else { continue }

            if game.status == .live {
                let content = LiveGameActivityAttributes.ContentState(
                    state: ActivityGameStateMapper.map(game)
                )
                await activity.update(ActivityContent(state: content, staleDate: staleDate()))
            } else {
                await end(activity: activity, game: game)
            }
        }

        return currentActiveGameID()
    }

    nonisolated private static func end(activity: Activity<LiveGameActivityAttributes>, game: Game) async {
        let content = LiveGameActivityAttributes.ContentState(
            state: ActivityGameStateMapper.map(game)
        )
        await activity.end(
            ActivityContent(state: content, staleDate: nil),
            dismissalPolicy: .default
        )
    }

    nonisolated private static func staleDate() -> Date {
        Date().addingTimeInterval(120)
    }
#endif

    nonisolated private static func currentActiveGameID() -> String? {
#if os(iOS) && canImport(ActivityKit)
        Activity<LiveGameActivityAttributes>.activities.first?.attributes.gameID
#else
        nil
#endif
    }
}
