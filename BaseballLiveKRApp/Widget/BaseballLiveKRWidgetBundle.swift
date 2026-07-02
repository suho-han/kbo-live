import WidgetKit
import SwiftUI

@main
struct BaseballLiveKRWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayGameWidget()
        LiveGameActivityWidget()
    }
}
