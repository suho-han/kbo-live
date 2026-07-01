import SwiftUI

public struct KboStatusPill: View {
    public enum Style: Sendable {
        case live
        case final
        case delayed
        case scheduled
        case neutral
    }

    private let text: String
    private let style: Style
    private let showsPulse: Bool
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.kboFontScale) private var fontScale

    public init(text: String, style: Style, showsPulse: Bool = false) {
        self.text = text
        self.style = style
        self.showsPulse = showsPulse
    }

    public var body: some View {
        HStack(spacing: 5) {
            if style == .live {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isPulsing && reduceMotion == false ? 1.26 : 1)
                    .opacity(isPulsing && reduceMotion == false ? 0.62 : 1)
            }

            Text(text)
                .font(KboTypographyToken.caption(scaledBy: fontScale))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, KboSpacingToken.small)
        .frame(minHeight: KboControlToken.pillHeight)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(borderColor, lineWidth: 1)
        }
        .onAppear {
            guard showsPulse, style == .live, reduceMotion == false else { return }
            withAnimation(KboMotionToken.livePulse) {
                isPulsing = true
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .live:
            return .white
        case .final:
            return KboSemanticColorToken.contentPrimary
        case .delayed:
            return .black.opacity(0.84)
        case .scheduled, .neutral:
            return KboSemanticColorToken.contentPrimary
        }
    }

    private var dotColor: Color {
        style == .live ? .white : foregroundColor
    }

    private var backgroundColor: Color {
        switch style {
        case .live:
            return KboSemanticColorToken.statusLive
        case .final:
            return KboSemanticColorToken.statusFinal.opacity(0.22)
        case .delayed:
            return KboSemanticColorToken.statusDelayed
        case .scheduled:
            return KboSemanticColorToken.statusScheduled.opacity(0.18)
        case .neutral:
            return KboSurfaceToken.glassControl
        }
    }

    private var borderColor: Color {
        switch style {
        case .live:
            return KboSemanticColorToken.statusLive.opacity(0.9)
        case .final:
            return KboSemanticColorToken.statusFinal.opacity(0.5)
        case .delayed:
            return KboSemanticColorToken.statusDelayed.opacity(0.8)
        case .scheduled:
            return KboSemanticColorToken.statusScheduled.opacity(0.5)
        case .neutral:
            return KboSurfaceToken.glassBorder
        }
    }
}
