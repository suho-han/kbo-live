import ActivityKit
import SwiftUI
import WidgetKit

struct LiveGameActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveGameActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text("\(context.attributes.awayTeamName) \(context.state.state.awayScore) : \(context.state.state.homeScore) \(context.attributes.homeTeamName)")
                    .font(.headline)

                if let inningText = context.state.state.inningText {
                    Text(inningText)
                        .font(.subheadline)
                }

                if let recentPlay = context.state.state.shortRecentPlay {
                    Text(recentPlay)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.82))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.awayTeamName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.homeTeamName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("\(context.state.state.awayScore)")
                        Text(":")
                        Text("\(context.state.state.homeScore)")
                        if let inningText = context.state.state.inningText {
                            Text(inningText)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Text("\(context.state.state.awayScore)")
            } compactTrailing: {
                Text("\(context.state.state.homeScore)")
            } minimal: {
                Text("KBO")
            }
        }
    }
}
