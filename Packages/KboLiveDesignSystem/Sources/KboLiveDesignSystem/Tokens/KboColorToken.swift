import SwiftUI

public enum KboColorToken {
    public static let backgroundPrimary = Color(red: 0.05, green: 0.07, blue: 0.10)
    public static let backgroundSecondary = Color(red: 0.09, green: 0.11, blue: 0.15)
    public static let surfaceCard = Color(red: 0.12, green: 0.14, blue: 0.19)
    public static let surfaceElevated = Color(red: 0.15, green: 0.18, blue: 0.24)
    public static let borderMuted = Color.white.opacity(0.12)

    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.72)
    public static let textMuted = Color.white.opacity(0.48)

    public static let statusLive = Color(red: 1.00, green: 0.27, blue: 0.36)
    public static let statusFinal = Color(red: 0.53, green: 0.58, blue: 0.66)
    public static let statusDelayed = Color(red: 1.00, green: 0.78, blue: 0.24)
    public static let statusScheduled = Color(red: 0.35, green: 0.72, blue: 1.00)

    public static let success = Color(red: 0.24, green: 0.84, blue: 0.56)
    public static let warning = statusDelayed
    public static let danger = statusLive
}
