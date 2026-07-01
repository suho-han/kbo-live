import Foundation

public enum GameProjectionFormatter {
    public static func inningText(for game: Game) -> String? {
        switch game.status {
        case .scheduled:
            if let startTime = game.startTime {
                return "\(DateFormatter.kboStartTime.string(from: startTime)) 예정"
            }
            return "예정"
        case .live:
            guard let inning = game.inning else {
                return "LIVE"
            }
            return "\(inning.number)회\(inning.half.koreanLabel)"
        case .final:
            return "종료"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return nil
        }
    }

    public static func menuBarSecondaryText(for game: Game) -> String? {
        let inningText = inningText(for: game)
        let outsText = game.status == .live ? outCountText(for: game.count?.outs) : nil

        let parts = [statusLabelText(for: game.status), inningText, outsText]
            .compactMap { $0 }
            .filter { $0.isEmpty == false }
            .reduce(into: [String]()) { partialResult, part in
                if partialResult.contains(part) == false {
                    partialResult.append(part)
                }
            }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    public static func shortRecentPlay(_ text: String?, limit: Int) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), trimmed.isEmpty == false else {
            return nil
        }

        guard trimmed.count > limit else {
            return trimmed
        }

        return String(trimmed.prefix(max(limit - 1, 0))) + "…"
    }

    public static func scoreLine(for game: Game) -> String {
        "\(game.awayTeam.name) \(game.score.away):\(game.score.home) \(game.homeTeam.name)"
    }

    public static func outCountText(for outs: Int?) -> String? {
        guard let outs else { return nil }
        return "\(outs)사"
    }

    public static func statusLabelText(for status: GameStatus) -> String? {
        switch status {
        case .scheduled:
            return nil
        case .live:
            return "LIVE"
        case .final:
            return "FINAL"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return nil
        }
    }
}

private extension InningHalf {
    var koreanLabel: String {
        switch self {
        case .top:
            return "초"
        case .bottom:
            return "말"
        }
    }
}

private extension DateFormatter {
    static let kboStartTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
