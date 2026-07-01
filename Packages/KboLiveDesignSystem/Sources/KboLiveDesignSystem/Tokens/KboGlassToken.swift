import SwiftUI

public enum KboGlassToken {
    public static func material(for style: KboGlassPanelStyle) -> Material {
        switch style {
        case .card:
            return .thinMaterial
        case .elevated:
            return .regularMaterial
        case .control, .navigation:
            return .ultraThinMaterial
        }
    }

    public static func opaqueSurface(for style: KboGlassPanelStyle) -> Color {
        switch style {
        case .card:
            return KboSurfaceToken.card
        case .elevated:
            return KboSurfaceToken.elevated
        case .control:
            return KboSurfaceToken.card.opacity(0.96)
        case .navigation:
            return KboSurfaceToken.elevated.opacity(0.98)
        }
    }

    public static func tintGradient(for style: KboGlassPanelStyle) -> LinearGradient {
        let colors: [Color]
        switch style {
        case .card:
            colors = [
                KboSurfaceToken.glassControl,
                KboSurfaceToken.card.opacity(0.62)
            ]
        case .elevated:
            colors = [
                KboSurfaceToken.glassNavigation,
                KboSurfaceToken.elevated.opacity(0.72)
            ]
        case .control:
            colors = [
                KboSemanticColorToken.accentBlue.opacity(0.12),
                KboSurfaceToken.glassControl
            ]
        case .navigation:
            colors = [
                KboSurfaceToken.elevated.opacity(0.74),
                KboSurfaceToken.glassNavigation
            ]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static func borderColor(for style: KboGlassPanelStyle) -> Color {
        switch style {
        case .card:
            return KboSurfaceToken.cardBorder
        case .elevated, .control, .navigation:
            return KboSurfaceToken.glassBorder
        }
    }

    public static func shadowColor(for style: KboGlassPanelStyle) -> Color {
        switch style {
        case .card:
            return KboColorToken.shadow.opacity(0.14)
        case .elevated:
            return KboColorToken.shadow.opacity(0.20)
        case .control, .navigation:
            return KboColorToken.shadow.opacity(0.12)
        }
    }

    public static func shadowRadius(for style: KboGlassPanelStyle) -> CGFloat {
        switch style {
        case .card, .control:
            return 10
        case .elevated:
            return 18
        case .navigation:
            return 14
        }
    }

    public static func shadowY(for style: KboGlassPanelStyle) -> CGFloat {
        switch style {
        case .card, .control:
            return 6
        case .elevated, .navigation:
            return 10
        }
    }
}
