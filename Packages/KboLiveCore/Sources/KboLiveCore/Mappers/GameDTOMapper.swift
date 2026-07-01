import Foundation

public enum GameDTOMapper {
    public static func map(_ dto: GameDTO, now: Date = Date()) -> Game {
        let startTime = parseStartTime(dto.startTime)
        let status = normalizedStatus(dto.status, startTime: startTime, now: now)
        let suppressPregameLiveState = dto.status == .live && status == .scheduled
        let inning = suppressPregameLiveState ? nil : dto.inning.map { InningState(number: $0.number, half: InningHalf(rawValue: $0.half.rawValue) ?? .top) }
        let count = suppressPregameLiveState ? nil : dto.count.map { CountState(balls: $0.balls, strikes: $0.strikes, outs: $0.outs) }
        let bases = suppressPregameLiveState ? nil : dto.bases.map { BasesState(first: $0.first, second: $0.second, third: $0.third) }
        let probablePitchers = ProbablePitchers(
            away: mapProbablePitcher(dto.probablePitchers.away),
            home: mapProbablePitcher(dto.probablePitchers.home)
        )
        let starterStatus = mapStarterStatus(dto.starterStatus, probablePitchers: probablePitchers)
        let current = suppressPregameLiveState ? nil : mapCurrentMatchup(dto.current)
        let recentPlay = suppressPregameLiveState
            ? nil
            : nilIfBlank(dto.recentPlay)

        return Game(
            id: dto.gameId,
            date: dto.date,
            venue: nilIfBlank(dto.venue),
            startTime: startTime,
            broadcastChannels: (dto.broadcastChannels ?? []).compactMap(nilIfBlank),
            homepageLinks: mapHomepageLinks(dto.homepageLinks),
            pitcherDecisions: mapPitcherDecisions(dto.pitcherDecisions),
            status: status,
            starterStatus: starterStatus,
            awayTeam: Team(id: dto.awayTeam.id, name: dto.awayTeam.name),
            homeTeam: Team(id: dto.homeTeam.id, name: dto.homeTeam.name),
            score: Score(away: dto.score.away, home: dto.score.home),
            inning: inning,
            count: count,
            bases: bases,
            current: current,
            probablePitchers: probablePitchers,
            recentPlay: recentPlay,
            teamRecords: mapTeamRecords(dto.teamRecords),
            boxScore: mapBoxScore(dto.boxScore),
            lineupPreview: mapLineupPreview(dto.lineupPreview),
            analysis: mapAnalysis(dto.analysis),
            sourceMeta: SourceMeta(
                rawStatusCode: dto.sourceMeta.rawStatusCode,
                rawTopBottomCode: dto.sourceMeta.rawTopBottomCode,
                fetchedAt: dto.sourceMeta.fetchedAt
            )
        )
    }

    static func mapCurrentMatchup(_ dto: CurrentMatchupDTO?) -> CurrentMatchup? {
        guard let dto else {
            return nil
        }

        return CurrentMatchup(
            batter: nilIfBlank(dto.batter),
            pitcher: nilIfBlank(dto.pitcher)
        )
    }

    static func mapProbablePitcher(_ dto: ProbablePitcherDTO?) -> ProbablePitcher {
        ProbablePitcher(
            name: nilIfBlank(dto?.name),
            record: mapPitcherSeasonSummary(dto?.record)
        )
    }

    static func mapPitcherSeasonSummary(_ dto: PitcherSeasonSummaryDTO?) -> PitcherSeasonSummary? {
        guard let dto else { return nil }
        let summary = PitcherSeasonSummary(
            wins: dto.wins,
            losses: dto.losses,
            era: dto.era,
            whip: dto.whip
        )
        guard summary.wins != nil || summary.losses != nil || summary.era != nil || summary.whip != nil else {
            return nil
        }
        return summary
    }

    static func mapStarterStatus(_ dto: StarterStatusDTO?, probablePitchers: ProbablePitchers) -> StarterStatus {
        guard let dto else {
            return probablePitchers.away.name != nil && probablePitchers.home.name != nil ? .ready : .notDue
        }

        switch dto {
        case .ready:
            return .ready
        case .missing:
            return .missing
        case .notDue:
            return .notDue
        }
    }

    static func normalizedStatus(_ dtoStatus: GameStatusDTO, startTime: Date?, now: Date) -> GameStatus {
        let status = GameStatus(rawValue: dtoStatus.rawValue) ?? .unknown
        guard status == .live,
              let startTime,
              now < startTime else {
            return status
        }

        return .scheduled
    }

    static func mapTeamRecords(_ dto: TeamRecordsDTO?) -> TeamRecords? {
        guard let dto else { return nil }
        return TeamRecords(
            away: dto.away.map(mapTeamRecordSummary),
            home: dto.home.map(mapTeamRecordSummary)
        )
    }

    static func mapHomepageLinks(_ dto: HomepageLinksDTO?) -> HomepageLinks? {
        guard let dto else { return nil }
        let links = HomepageLinks(
            gameCenter: nilIfBlank(dto.gameCenter),
            preview: nilIfBlank(dto.preview),
            review: nilIfBlank(dto.review),
            highlight: nilIfBlank(dto.highlight)
        )
        guard links.gameCenter != nil || links.preview != nil || links.review != nil || links.highlight != nil else {
            return nil
        }
        return links
    }

    static func mapPitcherDecisions(_ dto: PitcherDecisionsDTO?) -> PitcherDecisions? {
        guard let dto else { return nil }
        let decisions = PitcherDecisions(
            win: nilIfBlank(dto.win),
            loss: nilIfBlank(dto.loss),
            save: nilIfBlank(dto.save)
        )
        guard decisions.win != nil || decisions.loss != nil || decisions.save != nil else {
            return nil
        }
        return decisions
    }

    static func mapTeamRecordSummary(_ dto: TeamRecordSummaryDTO) -> TeamRecordSummary {
        TeamRecordSummary(
            wins: dto.wins,
            losses: dto.losses,
            draws: dto.draws,
            rank: dto.rank,
            streak: nilIfBlank(dto.streak)
        )
    }

    static func mapBoxScore(_ dto: BoxScoreDTO?) -> BoxScore? {
        guard let dto else { return nil }
        return BoxScore(
            away: mapTeamBoxScore(dto.away),
            home: mapTeamBoxScore(dto.home),
            linescore: dto.linescore.map { InningScore(inning: $0.inning, away: $0.away, home: $0.home) }
        )
    }

    static func mapTeamBoxScore(_ dto: TeamBoxScoreDTO) -> TeamBoxScore {
        TeamBoxScore(runs: dto.runs, hits: dto.hits, errors: dto.errors, walks: dto.walks)
    }

    static func mapLineupPreview(_ dto: LineupPreviewDTO?) -> LineupPreview? {
        guard let dto else { return nil }
        let away = dto.away.compactMap(nilIfBlank)
        let home = dto.home.compactMap(nilIfBlank)
        guard !away.isEmpty || !home.isEmpty else { return nil }
        return LineupPreview(away: away, home: home)
    }

    static func mapAnalysis(_ dto: TeamAnalysisDTO?) -> TeamAnalysis? {
        guard let dto else { return nil }
        let keyPoints = dto.keyPoints.compactMap(nilIfBlank)
        let awaySummary = nilIfBlank(dto.awaySummary)
        let homeSummary = nilIfBlank(dto.homeSummary)
        guard awaySummary != nil || homeSummary != nil || !keyPoints.isEmpty else { return nil }
        return TeamAnalysis(awaySummary: awaySummary, homeSummary: homeSummary, keyPoints: keyPoints)
    }

    static func nilIfBlank(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func parseStartTime(_ value: String?) -> Date? {
        guard let value = nilIfBlank(value) else { return nil }
        return makeKboStartTimeDateFormatter().date(from: value)
            ?? makeKboBasicDateFormatter().date(from: value)
            ?? makeKboExtendedDateFormatter().date(from: value)
    }

    private static func makeKboStartTimeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd'T'HH:mm:ssXXXXX"
        return formatter
    }

    private static func makeKboBasicDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withTimeZone]
        return formatter
    }

    private static func makeKboExtendedDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
