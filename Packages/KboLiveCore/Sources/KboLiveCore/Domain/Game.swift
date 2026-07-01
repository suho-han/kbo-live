import Foundation

public struct Game: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let date: String
    public let venue: String?
    public let startTime: Date?
    public let broadcastChannels: [String]
    public let homepageLinks: HomepageLinks?
    public let pitcherDecisions: PitcherDecisions?
    public let status: GameStatus
    public let starterStatus: StarterStatus
    public let awayTeam: Team
    public let homeTeam: Team
    public let score: Score
    public let inning: InningState?
    public let count: CountState?
    public let bases: BasesState?
    public let current: CurrentMatchup?
    public let probablePitchers: ProbablePitchers
    public let recentPlay: String?
    public let teamRecords: TeamRecords?
    public let boxScore: BoxScore?
    public let lineupPreview: LineupPreview?
    public let analysis: TeamAnalysis?
    public let sourceMeta: SourceMeta

    public init(
        id: String,
        date: String,
        venue: String?,
        startTime: Date?,
        broadcastChannels: [String] = [],
        homepageLinks: HomepageLinks? = nil,
        pitcherDecisions: PitcherDecisions? = nil,
        status: GameStatus,
        starterStatus: StarterStatus = .ready,
        awayTeam: Team,
        homeTeam: Team,
        score: Score,
        inning: InningState?,
        count: CountState?,
        bases: BasesState?,
        current: CurrentMatchup?,
        probablePitchers: ProbablePitchers,
        recentPlay: String?,
        teamRecords: TeamRecords? = nil,
        boxScore: BoxScore? = nil,
        lineupPreview: LineupPreview? = nil,
        analysis: TeamAnalysis? = nil,
        sourceMeta: SourceMeta
    ) {
        self.id = id
        self.date = date
        self.venue = venue
        self.startTime = startTime
        self.broadcastChannels = broadcastChannels
        self.homepageLinks = homepageLinks
        self.pitcherDecisions = pitcherDecisions
        self.status = status
        self.starterStatus = starterStatus
        self.awayTeam = awayTeam
        self.homeTeam = homeTeam
        self.score = score
        self.inning = inning
        self.count = count
        self.bases = bases
        self.current = current
        self.probablePitchers = probablePitchers
        self.recentPlay = recentPlay
        self.teamRecords = teamRecords
        self.boxScore = boxScore
        self.lineupPreview = lineupPreview
        self.analysis = analysis
        self.sourceMeta = sourceMeta
    }
}

public struct Team: Sendable, Equatable, Hashable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct Score: Sendable, Equatable, Hashable {
    public let away: Int
    public let home: Int

    public init(away: Int, home: Int) {
        self.away = away
        self.home = home
    }
}

public struct InningState: Sendable, Equatable, Hashable {
    public let number: Int
    public let half: InningHalf

    public init(number: Int, half: InningHalf) {
        self.number = number
        self.half = half
    }
}

public struct CountState: Sendable, Equatable, Hashable {
    public let balls: Int
    public let strikes: Int
    public let outs: Int

    public init(balls: Int, strikes: Int, outs: Int) {
        self.balls = balls
        self.strikes = strikes
        self.outs = outs
    }
}

public struct BasesState: Codable, Sendable, Equatable, Hashable {
    public let first: Bool
    public let second: Bool
    public let third: Bool

    public init(first: Bool, second: Bool, third: Bool) {
        self.first = first
        self.second = second
        self.third = third
    }
}

public struct CurrentMatchup: Sendable, Equatable, Hashable {
    public let batter: String?
    public let pitcher: String?

    public init(batter: String?, pitcher: String?) {
        self.batter = batter
        self.pitcher = pitcher
    }
}

public struct ProbablePitchers: Sendable, Equatable, Hashable {
    public let away: ProbablePitcher
    public let home: ProbablePitcher

    public init(away: ProbablePitcher, home: ProbablePitcher) {
        self.away = away
        self.home = home
    }
}

public struct ProbablePitcher: Sendable, Equatable, Hashable {
    public let name: String?
    public let record: PitcherSeasonSummary?

    public init(name: String?, record: PitcherSeasonSummary? = nil) {
        self.name = name
        self.record = record
    }
}

public struct PitcherSeasonSummary: Sendable, Equatable, Hashable {
    public let wins: Int?
    public let losses: Int?
    public let era: Double?
    public let whip: Double?

    public init(wins: Int?, losses: Int?, era: Double?, whip: Double?) {
        self.wins = wins
        self.losses = losses
        self.era = era
        self.whip = whip
    }
}

public struct HomepageLinks: Sendable, Equatable, Hashable {
    public let gameCenter: String?
    public let preview: String?
    public let review: String?
    public let highlight: String?

    public init(gameCenter: String? = nil, preview: String? = nil, review: String? = nil, highlight: String? = nil) {
        self.gameCenter = gameCenter
        self.preview = preview
        self.review = review
        self.highlight = highlight
    }
}

public struct PitcherDecisions: Sendable, Equatable, Hashable {
    public let win: String?
    public let loss: String?
    public let save: String?

    public init(win: String? = nil, loss: String? = nil, save: String? = nil) {
        self.win = win
        self.loss = loss
        self.save = save
    }
}

public struct TeamRecords: Sendable, Equatable, Hashable {
    public let away: TeamRecordSummary?
    public let home: TeamRecordSummary?

    public init(away: TeamRecordSummary?, home: TeamRecordSummary?) {
        self.away = away
        self.home = home
    }
}

public struct TeamRecordSummary: Sendable, Equatable, Hashable {
    public let wins: Int
    public let losses: Int
    public let draws: Int
    public let rank: Int?
    public let streak: String?

    public init(wins: Int, losses: Int, draws: Int, rank: Int? = nil, streak: String? = nil) {
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.rank = rank
        self.streak = streak
    }
}

public struct BoxScore: Sendable, Equatable, Hashable {
    public let away: TeamBoxScore
    public let home: TeamBoxScore
    public let linescore: [InningScore]

    public init(away: TeamBoxScore, home: TeamBoxScore, linescore: [InningScore] = []) {
        self.away = away
        self.home = home
        self.linescore = linescore
    }
}

public struct TeamBoxScore: Sendable, Equatable, Hashable {
    public let runs: Int
    public let hits: Int?
    public let errors: Int?
    public let walks: Int?

    public init(runs: Int, hits: Int? = nil, errors: Int? = nil, walks: Int? = nil) {
        self.runs = runs
        self.hits = hits
        self.errors = errors
        self.walks = walks
    }
}

public struct InningScore: Sendable, Equatable, Hashable, Identifiable {
    public let inning: Int
    public let away: Int?
    public let home: Int?

    public var id: Int { inning }

    public init(inning: Int, away: Int?, home: Int?) {
        self.inning = inning
        self.away = away
        self.home = home
    }
}

public struct LineupPreview: Sendable, Equatable, Hashable {
    public let away: [String]
    public let home: [String]

    public init(away: [String] = [], home: [String] = []) {
        self.away = away
        self.home = home
    }
}

public struct TeamAnalysis: Sendable, Equatable, Hashable {
    public let awaySummary: String?
    public let homeSummary: String?
    public let keyPoints: [String]

    public init(awaySummary: String? = nil, homeSummary: String? = nil, keyPoints: [String] = []) {
        self.awaySummary = awaySummary
        self.homeSummary = homeSummary
        self.keyPoints = keyPoints
    }
}

public struct SourceMeta: Sendable, Equatable, Hashable {
    public let rawStatusCode: String?
    public let rawTopBottomCode: String?
    public let fetchedAt: String

    public init(rawStatusCode: String?, rawTopBottomCode: String?, fetchedAt: String) {
        self.rawStatusCode = rawStatusCode
        self.rawTopBottomCode = rawTopBottomCode
        self.fetchedAt = fetchedAt
    }
}

public enum GameStatus: String, Codable, Sendable, Equatable, Hashable {
    case scheduled
    case live
    case final
    case delayed
    case cancelled
    case unknown
}

public enum StarterStatus: String, Codable, Sendable, Equatable, Hashable {
    case ready
    case missing
    case notDue
}

public enum InningHalf: String, Sendable, Equatable, Hashable {
    case top
    case bottom
}
