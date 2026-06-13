import SwiftUI
import WidgetKit

struct TodayGameEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetGameSnapshot
}

struct TodayGameProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayGameEntry {
        TodayGameEntry(date: .now, snapshot: SampleGameFactory.widgetSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayGameEntry) -> Void) {
        completion(TodayGameEntry(date: .now, snapshot: SampleGameFactory.widgetSnapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayGameEntry>) -> Void) {
        let entry = TodayGameEntry(date: .now, snapshot: SampleGameFactory.widgetSnapshot)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

struct TodayGameWidget: Widget {
    let kind = "TodayGameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayGameProvider()) { entry in
            TodayGameWidgetView(entry: entry)
        }
        .configurationDisplayName("대표 경기")
        .description("오늘 경기 중 대표 경기의 점수와 상태를 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct TodayGameWidgetView: View {
    let entry: TodayGameEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.snapshot.awayTeamName)
                Spacer()
                Text("\(entry.snapshot.awayScore)")
            }
            .font(.headline)

            HStack {
                Text(entry.snapshot.homeTeamName)
                Spacer()
                Text("\(entry.snapshot.homeScore)")
            }
            .font(.headline)

            if let inningText = entry.snapshot.inningText {
                Text(inningText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let recentPlay = entry.snapshot.recentPlay {
                Text(recentPlay)
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
