import SwiftUI

public enum KboGlassPanelStyle: Sendable {
    case card
    case elevated
    case control
    case navigation
}

public struct KboGlassPanel<Content: View>: View {
    private let style: KboGlassPanelStyle
    private let cornerRadius: CGFloat
    private let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        style: KboGlassPanelStyle = .card,
        cornerRadius: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background(panelBackground)
            .clipShape(shape)
            .overlay {
                shape.stroke(borderColor, lineWidth: 1)
            }
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    private var panelBackground: some View {
        if reduceTransparency {
            shape.fill(KboGlassToken.opaqueSurface(for: style))
        } else {
            shape.fill(KboGlassToken.material(for: style))
            shape.fill(KboGlassToken.tintGradient(for: style))
        }
    }

    private var borderColor: Color {
        KboGlassToken.borderColor(for: style)
    }

    private var shadowColor: Color {
        KboGlassToken.shadowColor(for: style)
    }

    private var shadowRadius: CGFloat {
        KboGlassToken.shadowRadius(for: style)
    }

    private var shadowY: CGFloat {
        KboGlassToken.shadowY(for: style)
    }
}
