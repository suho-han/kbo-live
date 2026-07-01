import SwiftUI

public enum KboSemanticColorToken {
    public static let accentBlue = Color(red: 0.18, green: 0.48, blue: 1.00)
    public static let accentMint = Color(red: 0.14, green: 0.78, blue: 0.64)
    public static let accentRed = KboColorToken.statusLive

    public static let contentPrimary = KboColorToken.textPrimary
    public static let contentSecondary = KboColorToken.textSecondary
    public static let contentMuted = KboColorToken.textMuted

    public static let statusLive = KboColorToken.statusLive
    public static let statusFinal = KboColorToken.statusFinal
    public static let statusDelayed = KboColorToken.statusDelayed
    public static let statusScheduled = KboColorToken.statusScheduled

    public static let success = KboColorToken.success
    public static let warning = KboColorToken.warning
    public static let danger = KboColorToken.danger
}
