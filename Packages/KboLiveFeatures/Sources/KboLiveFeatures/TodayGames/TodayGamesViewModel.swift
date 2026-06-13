import Foundation
import Combine
#if canImport(KboLiveCore)
import KboLiveCore
#endif

@MainActor
public final class TodayGamesViewModel: ObservableObject {
    public enum State: Equatable {
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
    @Published public private(set) var lastUpdatedAt: Date?
    @Published public private(set) var requestDate: String?
    @Published public private(set) var responseDate: String?

    private let client: GameFeedClient
    private let now: @Sendable () -> Date
    private let loadSelectedTeamID: @Sendable () -> String?
    private let saveSelectedTeamID: @Sendable (String?) -> Void
    private var pollingTask: Task<Void, Never>?
    private var pollingDate: String?

    public convenience init(
        client: GameFeedClient,
        title: String = "오늘 경기",
        filter: GameListFilter = .all,
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
        filter: GameListFilter = .all,
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
        TodayGames(date: requestDate ?? "", games: games).orderedGames(filter: filter)
    }

    public var isLoading: Bool {
        state == .loading
    }

    public var allTeams: [KboTeamOption] {
        KboTeamOption.all
    }

    public var selectedTeam: KboTeamOption? {
        guard let selectedTeamID else { return nil }
        return allTeams.first(where: { $0.id == selectedTeamID })
    }

    public var favoriteGame: Game? {
        guard let selectedTeamID else { return nil }
        return TodayGames(date: activeDateString, games: games)
            .orderedGames(filter: .all)
            .first(where: { $0.involves(teamID: selectedTeamID) })
    }

    public var leagueGames: [Game] {
        TodayGames(date: activeDateString, games: games).orderedGames(filter: filter)
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

        do {
            let response = try await client.fetchTodayGames(date: effectiveRequestDate)
            games = response.games
            responseDate = response.date
            lastUpdatedAt = now()
            state = .loaded
            restartPollingIfNeeded(date: effectiveRequestDate)
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    public func refresh() async {
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
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           description.isEmpty == false {
            return description
        }

        return "경기 데이터를 불러오지 못했습니다."
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
