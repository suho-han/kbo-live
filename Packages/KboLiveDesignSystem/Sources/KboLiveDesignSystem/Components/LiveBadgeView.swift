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
        Text(text)
            .font(KboTypographyToken.caption)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, KboSpacingToken.small)
            .padding(.vertical, 5)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            }
    }

    private var foregroundColor: Color {
        switch style {
        case .live:
            return .white
        case .final:
            return KboColorToken.textPrimary
        case .delayed:
            return .black.opacity(0.84)
        case .scheduled:
            return KboColorToken.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .live:
            return KboColorToken.statusLive
        case .final:
            return KboColorToken.statusFinal.opacity(0.22)
        case .delayed:
            return KboColorToken.statusDelayed
        case .scheduled:
            return KboColorToken.statusScheduled.opacity(0.18)
        }
    }

    private var borderColor: Color {
        switch style {
        case .live:
            return KboColorToken.statusLive.opacity(0.9)
        case .final:
            return KboColorToken.statusFinal.opacity(0.5)
        case .delayed:
            return KboColorToken.statusDelayed.opacity(0.8)
        case .scheduled:
            return KboColorToken.statusScheduled.opacity(0.5)
        }
    }
}
