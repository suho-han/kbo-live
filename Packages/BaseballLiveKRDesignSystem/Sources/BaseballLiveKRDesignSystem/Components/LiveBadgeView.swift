import SwiftUI

public struct LiveBadgeView: View {
    public enum Style: Sendable {
        case live
        case final
        case delayed
        case scheduled
    }

    private let text: String
    private let style: Style

    public init(text: String, style: Style) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        KboStatusPill(text: text, style: statusStyle, showsPulse: style == .live)
    }

    private var statusStyle: KboStatusPill.Style {
        switch style {
        case .live:
            return .live
        case .final:
            return .final
        case .delayed:
            return .delayed
        case .scheduled:
            return .scheduled
        }
    }
}
