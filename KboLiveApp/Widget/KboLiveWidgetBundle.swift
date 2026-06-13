import WidgetKit
import SwiftUI

@main
struct KboLiveWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayGameWidget()
        LiveGameActivityWidget()
    }
}
