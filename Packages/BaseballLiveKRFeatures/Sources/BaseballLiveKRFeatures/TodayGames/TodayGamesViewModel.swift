import Foundation
import Combine
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif

public struct TodayDashboardSummary: Equatable, Sendable {
    public let totalGames: Int
    public let liveGames: Int
    public let scheduledGames: Int
    public let finalGames: Int
    public let headline: String
    public let detail: String
}

@MainActor
public final class TodayGamesViewModel: ObservableObject {
    public enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(message: String)
    }

    public enum TeamStandingsState: Equatable {
        case idle
        case loading
        case loaded
        case failed(message: String)
    }

    public let title: String
    @Published public var filter: GameListFilter
    @Published public private(set) var selectedTeamID: String?
    @Published public private(set) var state: State
    @Published public private(set) var games: [Game]
    @Published public private(set) var standingsState: TeamStandingsState
    @Published public private(set) var standings: [TeamStanding]
    @Published public private(set) var lastUpdatedAt: Date?
    @Published public private(set) var requestDate: String?
    @Published public private(set) var responseDate: String?

    private var client: GameFeedClient
    private let now: @Sendable () -> Date
    private let loadSelectedTeamID: @Sendable () -> String?
    private let saveSelectedTeamID: @Sendable (String?) -> Void
    private var pollingTask: Task<Void, Never>?
    private var pollingDate: String?
    private var hasAppliedInitialFilter = false
    private var hasUserSelectedFilter = false

    public convenience init(
        client: GameFeedClient,
        title: String = "오늘 경기",
        filter: GameListFilter = .live,
        selectedTeamID: String? = nil,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        let selectedTeamKey = "kbo-live.selected-team-id"
        self.init(
            client: client,
            title: title,
            filter: filter,
            selectedTeamID: selectedTeamID,
            loadSelectedTeamID: {
                UserDefaults.standard.string(forKey: selectedTeamKey)
            },
            saveSelectedTeamID: { teamID in
                if let teamID, teamID.isEmpty == false {
                    UserDefaults.standard.set(teamID, forKey: selectedTeamKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: selectedTeamKey)
                }
            },
            now: now
        )
    }

    init(
        client: GameFeedClient,
        title: String = "오늘 경기",
        filter: GameListFilter = .live,
        selectedTeamID: String? = nil,
        loadSelectedTeamID: @escaping @Sendable () -> String?,
        saveSelectedTeamID: @escaping @Sendable (String?) -> Void,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.client = client
        self.title = title
        self.filter = filter
        self.loadSelectedTeamID = loadSelectedTeamID
        self.saveSelectedTeamID = saveSelectedTeamID
        self.selectedTeamID = selectedTeamID ?? loadSelectedTeamID()
        self.state = .idle
        self.games = []
        self.standingsState = .idle
        self.standings = []
        self.lastUpdatedAt = nil
        self.requestDate = nil
        self.responseDate = nil
        self.pollingTask = nil
        self.pollingDate = nil
        self.now = now
    }

    deinit {
        pollingTask?.cancel()
    }

    public var visibleGames: [Game] {
        TodayGames(date: requestDate ?? "", games: games).orderedGames(
            filter: filter,
            preferredTeamID: selectedTeamID
        )
    }

    public var isLoading: Bool {
        state == .loading
    }

    public var allTeams: [KboTeamOption] {
        KboTeamOption.sortedByStandings(games: games)
    }

    public var selectedTeam: KboTeamOption? {
        guard let selectedTeamID else { return nil }
        return allTeams.first(where: { $0.id == selectedTeamID })
    }

    public var favoriteGame: Game? {
        guard let selectedTeamID else { return nil }
        return TodayGames(date: activeDateString, games: games)
            .orderedGames(filter: .all, preferredTeamID: selectedTeamID)
            .first(where: { $0.involves(teamID: selectedTeamID) })
    }

    public var leagueGames: [Game] {
        TodayGames(date: activeDateString, games: games).orderedGames(
            filter: filter,
            preferredTeamID: selectedTeamID
        )
    }

    public var dashboardSummary: TodayDashboardSummary {
        let liveGames = games.filter { $0.status == .live }.count
        let scheduledGames = games.filter { $0.status == .scheduled || $0.status == .delayed }.count
        let finalGames = games.filter { $0.status == .final || $0.status == .cancelled }.count
        let countsText = Self.countsText(
            totalGames: games.count,
            liveGames: liveGames,
            scheduledGames: scheduledGames,
            finalGames: finalGames
        )
        let headline: String
        let detail: String

        if let favoriteGame {
            headline = Self.headline(for: favoriteGame)
            detail = Self.detail(for: favoriteGame, countsText: countsText)
        } else if let selectedTeam {
            headline = "오늘은 \(selectedTeam.name) 경기가 없습니다"
            detail = countsText
        } else if let spotlightGame = TodayGames(date: activeDateString, games: games)
            .orderedGames(filter: .all, preferredTeamID: selectedTeamID)
            .first {
            headline = Self.headline(for: spotlightGame)
            detail = Self.detail(for: spotlightGame, countsText: countsText)
        } else {
            headline = "오늘 편성된 경기가 없습니다"
            detail = countsText
        }

        return TodayDashboardSummary(
            totalGames: games.count,
            liveGames: liveGames,
            scheduledGames: scheduledGames,
            finalGames: finalGames,
            headline: headline,
            detail: detail
        )
    }

    public var standingsErrorMessage: String? {
        guard case let .failed(message) = standingsState else { return nil }
        return message
    }

    public var activeDateString: String {
        requestDate ?? responseDate ?? ""
    }

    public var errorMessage: String? {
        guard case let .failed(message) = state else { return nil }
        return message
    }

    public func selectTeam(_ teamID: String?) {
        selectedTeamID = teamID
        saveSelectedTeamID(teamID)
    }

    public func setFilter(_ filter: GameListFilter) {
        hasUserSelectedFilter = true
        self.filter = filter
    }

    public func loadIfNeeded(date: String? = nil) async {
        guard state == .idle else { return }
        await load(date: date)
    }

    public func load(date: String? = nil) async {
        if let date {
            requestDate = date
        }
        let effectiveRequestDate = requestDate

        if games.isEmpty {
            state = .loading
        }
        if standings.isEmpty {
            standingsState = .loading
        }

        do {
            let response = try await client.fetchTodayGames(date: effectiveRequestDate)
            games = response.games
            responseDate = response.date
            lastUpdatedAt = now()
            applyInitialFilterIfNeeded()
            state = .loaded
            restartPollingIfNeeded(date: effectiveRequestDate)
        } catch {
            state = .failed(message: Self.message(for: error))
        }

        await loadStandings(date: effectiveRequestDate)
    }

    public func refresh() async {
        await load(date: requestDate)
    }

    public func updateClient(_ client: GameFeedClient) async {
        pollingTask?.cancel()
        pollingTask = nil
        pollingDate = nil
        self.client = client
        state = .idle
        games = []
        standingsState = .idle
        standings = []
        lastUpdatedAt = nil
        responseDate = nil
        hasAppliedInitialFilter = false
        await load(date: requestDate)
    }

    public func makeDetailViewModel(for game: Game) -> GameDetailViewModel {
        GameDetailViewModel(
            client: client,
            gameID: game.id,
            requestDate: requestDate ?? game.date,
            now: now
        )
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

        return "경기 데이터를 불러오지 못했습니다."
    }

    private static func headline(for game: Game) -> String {
        switch game.status {
        case .scheduled, .delayed, .cancelled, .unknown:
            return "\(game.awayTeam.name) vs \(game.homeTeam.name)"
        case .live, .final:
            return GameProjectionFormatter.scoreLine(for: game)
        }
    }

    private static func detail(for game: Game, countsText: String) -> String {
        var parts: [String] = []

        if game.status == .live, game.inning == nil {
            parts.append(shortStatusText(for: game.status))
        } else if let gameStateText = GameProjectionFormatter.inningText(for: game), gameStateText.isEmpty == false {
            parts.append(gameStateText)
        } else {
            parts.append(shortStatusText(for: game.status))
        }

        if let venue = game.venue?.trimmingCharacters(in: .whitespacesAndNewlines), venue.isEmpty == false {
            parts.append(venue)
        }

        parts.append(countsText)
        return parts.joined(separator: " · ")
    }

    private static func countsText(totalGames: Int, liveGames: Int, scheduledGames: Int, finalGames: Int) -> String {
        "전체 \(totalGames)경기 · 진행 \(liveGames) · 예정 \(scheduledGames) · 종료 \(finalGames)"
    }

    private static func shortStatusText(for status: GameStatus) -> String {
        switch status {
        case .scheduled:
            return "예정"
        case .live:
            return "진행 중"
        case .final:
            return "종료"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return "확인 중"
        }
    }

    private func loadStandings(date: String?) async {
        if standings.isEmpty {
            standingsState = .loading
        }

        do {
            let response = try await client.fetchTeamStandings(date: date)
            standings = response.standings
            standingsState = .loaded
        } catch {
            let fallbackStandings = standingsFromGameRecords()
            if fallbackStandings.isEmpty {
                standingsState = .failed(message: Self.message(for: error))
            } else {
                standings = fallbackStandings
                standingsState = .loaded
            }
        }
    }

    private func standingsFromGameRecords() -> [TeamStanding] {
        var standingsByTeamID: [String: TeamStanding] = [:]

        for game in games {
            if let awayRecord = game.teamRecords?.away {
                standingsByTeamID[game.awayTeam.id] = Self.standing(team: game.awayTeam, record: awayRecord)
            }

            if let homeRecord = game.teamRecords?.home {
                standingsByTeamID[game.homeTeam.id] = Self.standing(team: game.homeTeam, record: homeRecord)
            }
        }

        return standingsByTeamID.values.sorted { lhs, rhs in
            let lhsRank = lhs.rank ?? Int.max
            let rhsRank = rhs.rank ?? Int.max
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }

            return lhs.team.id < rhs.team.id
        }
    }

    private static func standing(team: Team, record: TeamRecordSummary) -> TeamStanding {
        TeamStanding(
            team: team,
            wins: record.wins,
            losses: record.losses,
            draws: record.draws,
            rank: record.rank,
            streak: record.streak
        )
    }

    private func applyInitialFilterIfNeeded() {
        guard hasAppliedInitialFilter == false,
              hasUserSelectedFilter == false,
              filter == .live else {
            return
        }

        hasAppliedInitialFilter = true
        let hasLiveGame = games.contains { GameListFilter.live.matches($0.status) }
        filter = hasLiveGame ? .live : .scheduled
    }

    private func restartPollingIfNeeded(date: String?) {
        guard pollingDate != date || pollingTask == nil else { return }

        pollingTask?.cancel()
        pollingDate = date
        pollingTask = Task { [weak self, client, now] in
            do {
                for try await update in client.streamTodayGames(date: date) {
                    guard let self else { return }
                    guard Task.isCancelled == false else { break }

                    self.games = update.games
                    self.responseDate = update.date
                    self.lastUpdatedAt = now()
                    self.state = .loaded
                }
            } catch {
                guard let self else { return }
                guard Task.isCancelled == false else { return }
                self.state = .failed(message: Self.message(for: error))
            }
        }
    }
}
