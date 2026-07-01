import Foundation

public struct TodayGamesResponseDTO: Decodable, Sendable {
    public let date: String
    public let games: [GameDTO]

    public init(date: String, games: [GameDTO]) {
        self.date = date
        self.games = games
    }
}

public struct GameDetailResponseDTO: Decodable, Sendable {
    public let date: String
    public let game: GameDTO?

    public init(date: String, game: GameDTO?) {
        self.date = date
        self.game = game
    }
}

public struct GameDTO: Decodable, Identifiable, Sendable {
    public let gameId: String
    public let date: String
    public let venue: String?
    public let startTime: String?
    public let broadcastChannels: [String]?
    public let homepageLinks: HomepageLinksDTO?
    public let pitcherDecisions: PitcherDecisionsDTO?
    public let status: GameStatusDTO
    public let starterStatus: StarterStatusDTO?
    public let awayTeam: TeamDTO
    public let homeTeam: TeamDTO
    public let score: ScoreDTO
    public let inning: InningDTO?
    public let count: CountDTO?
    public let bases: BasesDTO?
    public let current: CurrentMatchupDTO?
    public let probablePitchers: ProbablePitchersDTO
    public let recentPlay: String?
    public let teamRecords: TeamRecordsDTO?
    public let boxScore: BoxScoreDTO?
    public let lineupPreview: LineupPreviewDTO?
    public let analysis: TeamAnalysisDTO?
    public let sourceMeta: SourceMetaDTO

    public var id: String { gameId }

    public init(
        gameId: String,
        date: String,
        venue: String?,
        startTime: String?,
        broadcastChannels: [String]? = nil,
        homepageLinks: HomepageLinksDTO? = nil,
        pitcherDecisions: PitcherDecisionsDTO? = nil,
        status: GameStatusDTO,
        starterStatus: StarterStatusDTO? = nil,
        awayTeam: TeamDTO,
        homeTeam: TeamDTO,
        score: ScoreDTO,
        inning: InningDTO?,
        count: CountDTO?,
        bases: BasesDTO?,
        current: CurrentMatchupDTO?,
        probablePitchers: ProbablePitchersDTO,
        recentPlay: String?,
        teamRecords: TeamRecordsDTO? = nil,
        boxScore: BoxScoreDTO? = nil,
        lineupPreview: LineupPreviewDTO? = nil,
        analysis: TeamAnalysisDTO? = nil,
        sourceMeta: SourceMetaDTO
    ) {
        self.gameId = gameId
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

public struct TeamDTO: Decodable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct ScoreDTO: Decodable, Sendable {
    public let away: Int
    public let home: Int

    public init(away: Int, home: Int) {
        self.away = away
        self.home = home
    }
}

public struct InningDTO: Decodable, Sendable {
    public let number: Int
    public let half: InningHalfDTO

    public init(number: Int, half: InningHalfDTO) {
        self.number = number
        self.half = half
    }
}

public struct CountDTO: Decodable, Sendable {
    public let balls: Int
    public let strikes: Int
    public let outs: Int

    public init(balls: Int, strikes: Int, outs: Int) {
        self.balls = balls
        self.strikes = strikes
        self.outs = outs
    }
}

public struct BasesDTO: Decodable, Sendable {
    public let first: Bool
    public let second: Bool
    public let third: Bool

    public init(first: Bool, second: Bool, third: Bool) {
        self.first = first
        self.second = second
        self.third = third
    }
}

public struct CurrentMatchupDTO: Decodable, Sendable {
    public let batter: String?
    public let pitcher: String?

    public init(batter: String?, pitcher: String?) {
        self.batter = batter
        self.pitcher = pitcher
    }
}

public struct ProbablePitchersDTO: Decodable, Sendable {
    public let away: ProbablePitcherDTO?
    public let home: ProbablePitcherDTO?

    public init(away: ProbablePitcherDTO?, home: ProbablePitcherDTO?) {
        self.away = away
        self.home = home
    }
}

public struct ProbablePitcherDTO: Decodable, Sendable {
    public let name: String?
    public let record: PitcherSeasonSummaryDTO?

    public init(name: String?, record: PitcherSeasonSummaryDTO? = nil) {
        self.name = name
        self.record = record
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case record
    }

    public init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           singleValue.decodeNil() == false,
           let legacyName = try? singleValue.decode(String.self) {
            self.name = legacyName
            self.record = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.record = try container.decodeIfPresent(PitcherSeasonSummaryDTO.self, forKey: .record)
    }
}

public struct PitcherSeasonSummaryDTO: Decodable, Sendable {
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

public struct HomepageLinksDTO: Decodable, Sendable {
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

public struct PitcherDecisionsDTO: Decodable, Sendable {
    public let win: String?
    public let loss: String?
    public let save: String?

    public init(win: String? = nil, loss: String? = nil, save: String? = nil) {
        self.win = win
        self.loss = loss
        self.save = save
    }
}

public struct TeamRecordsDTO: Decodable, Sendable {
    public let away: TeamRecordSummaryDTO?
    public let home: TeamRecordSummaryDTO?

    public init(away: TeamRecordSummaryDTO?, home: TeamRecordSummaryDTO?) {
        self.away = away
        self.home = home
    }
}

public struct TeamRecordSummaryDTO: Decodable, Sendable {
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

public struct BoxScoreDTO: Decodable, Sendable {
    public let away: TeamBoxScoreDTO
    public let home: TeamBoxScoreDTO
    public let linescore: [InningScoreDTO]

    public init(away: TeamBoxScoreDTO, home: TeamBoxScoreDTO, linescore: [InningScoreDTO] = []) {
        self.away = away
        self.home = home
        self.linescore = linescore
    }
}

public struct TeamBoxScoreDTO: Decodable, Sendable {
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

public struct InningScoreDTO: Decodable, Sendable {
    public let inning: Int
    public let away: Int?
    public let home: Int?

    public init(inning: Int, away: Int?, home: Int?) {
        self.inning = inning
        self.away = away
        self.home = home
    }
}

public struct LineupPreviewDTO: Decodable, Sendable {
    public let away: [String]
    public let home: [String]

    public init(away: [String] = [], home: [String] = []) {
        self.away = away
        self.home = home
    }
}

public struct TeamAnalysisDTO: Decodable, Sendable {
    public let awaySummary: String?
    public let homeSummary: String?
    public let keyPoints: [String]

    public init(awaySummary: String? = nil, homeSummary: String? = nil, keyPoints: [String] = []) {
        self.awaySummary = awaySummary
        self.homeSummary = homeSummary
        self.keyPoints = keyPoints
    }
}

public struct SourceMetaDTO: Decodable, Sendable {
    public let rawStatusCode: String?
    public let rawTopBottomCode: String?
    public let fetchedAt: String

    public init(rawStatusCode: String?, rawTopBottomCode: String?, fetchedAt: String) {
        self.rawStatusCode = rawStatusCode
        self.rawTopBottomCode = rawTopBottomCode
        self.fetchedAt = fetchedAt
    }
}

public enum GameStatusDTO: String, Decodable, Sendable {
    case scheduled
    case live
    case final
    case delayed
    case cancelled
    case unknown
}

public enum StarterStatusDTO: String, Decodable, Sendable {
    case ready
    case missing
    case notDue
}

public enum InningHalfDTO: String, Decodable, Sendable {
    case top
    case bottom
}
