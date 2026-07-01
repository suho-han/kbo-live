import Foundation

public struct ActivityGameState: Codable, Hashable, Sendable {
    public let awayScore: Int
    public let homeScore: Int
    public let status: ActivityStatus
    public let inningText: String?
    public let outs: Int?
    public let hasRunnerOnFirst: Bool
    public let hasRunnerOnSecond: Bool
    public let hasRunnerOnThird: Bool
    public let shortRecentPlay: String?

    public init(
        awayScore: Int,
        homeScore: Int,
        status: ActivityStatus,
        inningText: String?,
        outs: Int?,
        hasRunnerOnFirst: Bool,
        hasRunnerOnSecond: Bool,
        hasRunnerOnThird: Bool,
        shortRecentPlay: String?
    ) {
        self.awayScore = awayScore
        self.homeScore = homeScore
        self.status = status
        self.inningText = inningText
        self.outs = outs
        self.hasRunnerOnFirst = hasRunnerOnFirst
        self.hasRunnerOnSecond = hasRunnerOnSecond
        self.hasRunnerOnThird = hasRunnerOnThird
        self.shortRecentPlay = shortRecentPlay
    }
}

public enum ActivityStatus: String, Codable, Hashable, Sendable {
    case scheduled
    case live
    case final
    case delayed
    case cancelled
    case unknown
}
