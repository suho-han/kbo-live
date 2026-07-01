import Foundation
#if os(iOS) && canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif

#if os(iOS) && canImport(ActivityKit)
struct LiveGameActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let state: ActivityGameState
    }

    let gameID: String
    let awayTeamName: String
    let homeTeamName: String
}
#endif
