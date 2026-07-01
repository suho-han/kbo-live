import Foundation

public enum GameListFilter: String, CaseIterable, Sendable {
    case all
    case live
    case scheduled
    case final

    public func matches(_ status: GameStatus) -> Bool {
        switch self {
        case .all:
            return true
        case .live:
            return status == .live
        case .scheduled:
            return status == .scheduled || status == .delayed
        case .final:
            return status == .final || status == .cancelled
        }
    }
}

public extension TodayGames {
    func orderedGames(filter: GameListFilter = .all, preferredTeamID: String? = nil) -> [Game] {
        games
            .enumerated()
            .filter { filter.matches($0.element.status) }
            .sorted { lhs, rhs in
                let lhsGame = lhs.element
                let rhsGame = rhs.element

                if let preferredTeamID, preferredTeamID.isEmpty == false {
                    let lhsIncludesPreferred = lhsGame.involves(teamID: preferredTeamID)
                    let rhsIncludesPreferred = rhsGame.involves(teamID: preferredTeamID)
                    if lhsIncludesPreferred != rhsIncludesPreferred {
                        return lhsIncludesPreferred
                    }
                }

                let lhsPriority = lhsGame.status.listPriority
                let rhsPriority = rhsGame.status.listPriority
                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }

                if let lhsStartTime = lhsGame.startTime,
                   let rhsStartTime = rhsGame.startTime,
                   lhsStartTime != rhsStartTime {
                    return lhsStartTime < rhsStartTime
                }

                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}

private extension GameStatus {
    var listPriority: Int {
        switch self {
        case .live:
            return 0
        case .scheduled:
            return 1
        case .delayed:
            return 2
        case .final:
            return 3
        case .cancelled:
            return 4
        case .unknown:
            return 5
        }
    }
}
