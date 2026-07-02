import SwiftUI
import WidgetKit

struct TodayGameEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetGameSnapshot
}

struct TodayGameProvider: TimelineProvider {
    private let store = WidgetGameSnapshotStore()

    func placeholder(in context: Context) -> TodayGameEntry {
        TodayGameEntry(date: .now, snapshot: SampleGameFactory.favoriteTeamWidgetSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayGameEntry) -> Void) {
        completion(TodayGameEntry(date: .now, snapshot: snapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayGameEntry>) -> Void) {
        let entry = TodayGameEntry(date: .now, snapshot: snapshot())
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }

    private func snapshot() -> WidgetGameSnapshot {
        store.snapshot ?? SampleGameFactory.favoriteTeamWidgetSnapshot
    }
}

struct TodayGameWidget: Widget {
    let kind = "TodayGameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayGameProvider()) { entry in
            TodayGameWidgetView(entry: entry)
        }
        .configurationDisplayName("나의 팀 경기")
        .description("응원팀 경기를 우선 표시하고, 없으면 리그 대표 경기를 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct TodayGameWidgetView: View {
    let entry: TodayGameEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            scoreRows

            if family != .systemSmall {
                contextSection
            } else if let recentPlay = entry.snapshot.recentPlay, entry.snapshot.status == .live {
                Text(recentPlay)
                    .font(.caption2.weight(.medium))
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(entry.snapshot.headline)
                .font(.caption.weight(.bold))
                .foregroundStyle(entry.snapshot.isFavoriteTeamGame ? .orange : .secondary)
                .lineLimit(1)

            Spacer(minLength: 6)

            Text(statusLabel)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .foregroundStyle(statusForegroundColor)
                .background(statusBackgroundColor)
                .clipShape(Capsule())
                .lineLimit(1)
        }
    }

    private var scoreRows: some View {
        VStack(alignment: .leading, spacing: 5) {
            teamScoreRow(name: entry.snapshot.awayTeamName, score: entry.snapshot.awayScore)
            teamScoreRow(name: entry.snapshot.homeTeamName, score: entry.snapshot.homeScore)
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let contextText = entry.snapshot.contextText {
                Text(contextText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let recentPlay = entry.snapshot.recentPlay {
                Text(recentPlay)
                    .font(.caption2.weight(.medium))
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            } else if entry.snapshot.fallbackKind != .none {
                Text(fallbackHelpText)
                    .font(.caption2.weight(.medium))
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func teamScoreRow(name: String, score: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(name)
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 6)

            Text(scoreText(score))
                .font(.title3.monospacedDigit().weight(.bold))
                .contentTransition(.numericText())
        }
    }

    private var statusLabel: String {
        switch entry.snapshot.status {
        case .scheduled:
            return "예정"
        case .live:
            return "LIVE"
        case .final:
            return "FINAL"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return "KBO"
        }
    }

    private var statusForegroundColor: Color {
        switch entry.snapshot.status {
        case .live:
            return .white
        case .delayed, .cancelled:
            return .orange
        default:
            return .secondary
        }
    }

    private var statusBackgroundColor: Color {
        switch entry.snapshot.status {
        case .live:
            return .red.opacity(0.82)
        case .delayed, .cancelled:
            return .orange.opacity(0.16)
        default:
            return .secondary.opacity(0.14)
        }
    }

    private var fallbackHelpText: String {
        switch entry.snapshot.fallbackKind {
        case .favoriteTeamNoGame:
            return "오늘은 리그 대표 경기로 대신 표시합니다."
        case .favoriteTeamNotSelected:
            return "앱에서 응원팀을 선택하면 위젯도 내 팀 중심으로 바뀝니다."
        case .none:
            return ""
        }
    }

    private func scoreText(_ score: Int) -> String {
        switch entry.snapshot.status {
        case .scheduled, .cancelled:
            return "-"
        default:
            return "\(score)"
        }
    }
}

#if DEBUG
#Preview("나의 팀", as: .systemSmall) {
    TodayGameWidget()
} timeline: {
    TodayGameEntry(date: .now, snapshot: SampleGameFactory.favoriteTeamWidgetSnapshot)
}

#Preview("응원팀 경기 없음", as: .systemMedium) {
    TodayGameWidget()
} timeline: {
    TodayGameEntry(date: .now, snapshot: SampleGameFactory.favoriteTeamNoGameWidgetSnapshot)
}

#Preview("응원팀 미선택", as: .systemMedium) {
    TodayGameWidget()
} timeline: {
    TodayGameEntry(date: .now, snapshot: SampleGameFactory.noFavoriteTeamSelectedWidgetSnapshot)
}
#endif
