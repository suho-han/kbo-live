import SwiftUI

public enum KboSurfaceToken {
    public static let contentBackground = KboColorToken.backgroundPrimary
    public static let card = KboColorToken.surfaceCard
    public static let elevated = KboColorToken.surfaceElevated
    public static let glassControl = KboColorToken.surfaceElevated.opacity(0.52)
    public static let glassNavigation = KboColorToken.surfaceElevated.opacity(0.62)
    public static let criticalOverlay = KboColorToken.shadow.opacity(0.42)

    public static let cardBorder = KboColorToken.borderMuted
    public static let glassBorder = KboColorToken.borderMuted.opacity(0.86)
    public static let focusBorder = KboSemanticColorToken.accentBlue.opacity(0.55)
}
