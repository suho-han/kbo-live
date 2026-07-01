import Foundation

public struct KboTeamOption: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public extension KboTeamOption {
    static let all: [KboTeamOption] = [
        KboTeamOption(id: "LG", name: "LG"),
        KboTeamOption(id: "OB", name: "두산"),
        KboTeamOption(id: "SK", name: "SSG"),
        KboTeamOption(id: "SS", name: "삼성"),
        KboTeamOption(id: "HT", name: "KIA"),
        KboTeamOption(id: "KT", name: "KT"),
        KboTeamOption(id: "LT", name: "롯데"),
        KboTeamOption(id: "HH", name: "한화"),
        KboTeamOption(id: "NC", name: "NC"),
        KboTeamOption(id: "WO", name: "키움")
    ]

    static let standingsFallbackOrder: [String] = [
        "LG",
        "KT",
        "SS",
        "HT",
        "OB",
        "HH",
        "NC",
        "SK",
        "WO",
        "LT"
    ]

    var koreanFullName: String {
        switch id {
        case "LG":
            return "LG 트윈스"
        case "OB":
            return "두산 베어스"
        case "SK":
            return "SSG 랜더스"
        case "SS":
            return "삼성 라이온즈"
        case "HT":
            return "기아 타이거즈"
        case "KT":
            return "KT 위즈"
        case "LT":
            return "롯데 자이언츠"
        case "HH":
            return "한화 이글스"
        case "NC":
            return "NC 다이노스"
        case "WO":
            return "키움 히어로즈"
        default:
            return name
        }
    }

    static func sortedByStandings(_ teams: [KboTeamOption] = KboTeamOption.all, games: [Game]) -> [KboTeamOption] {
        let actualRanks = standingsRanks(from: games)
        let fallbackRanks = Dictionary(
            uniqueKeysWithValues: standingsFallbackOrder.enumerated().map { index, teamID in
                (teamID, index + 1)
            }
        )
        let originalIndexes = Dictionary(
            uniqueKeysWithValues: teams.enumerated().map { index, team in
                (team.id, index)
            }
        )

        return teams.sorted { lhs, rhs in
            let lhsRank = actualRanks[lhs.id] ?? fallbackRanks[lhs.id] ?? Int.max
            let rhsRank = actualRanks[rhs.id] ?? fallbackRanks[rhs.id] ?? Int.max

            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }

            return (originalIndexes[lhs.id] ?? Int.max) < (originalIndexes[rhs.id] ?? Int.max)
        }
    }

    private static func standingsRanks(from games: [Game]) -> [String: Int] {
        var ranks: [String: Int] = [:]

        for game in games {
            setRank(game.teamRecords?.away?.rank, for: game.awayTeam.id, in: &ranks)
            setRank(game.teamRecords?.home?.rank, for: game.homeTeam.id, in: &ranks)
        }

        return ranks
    }

    private static func setRank(_ rank: Int?, for teamID: String, in ranks: inout [String: Int]) {
        guard let rank else { return }

        if let existingRank = ranks[teamID] {
            ranks[teamID] = min(existingRank, rank)
        } else {
            ranks[teamID] = rank
        }
    }
}

public extension Game {
    func involves(teamID: String) -> Bool {
        awayTeam.id == teamID || homeTeam.id == teamID
    }

    func team(named teamID: String) -> Team? {
        if awayTeam.id == teamID {
            return awayTeam
        }

        if homeTeam.id == teamID {
            return homeTeam
        }

        return nil
    }
}
