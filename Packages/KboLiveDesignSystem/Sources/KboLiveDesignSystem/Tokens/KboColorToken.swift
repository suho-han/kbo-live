import SwiftUI

public enum KboColorToken {
    public static let backgroundPrimary = Color(red: 0.04, green: 0.07, blue: 0.10)
    public static let backgroundSecondary = Color(red: 0.07, green: 0.11, blue: 0.14)
    public static let appBackgroundTop = Color(red: 0.05, green: 0.13, blue: 0.16)
    public static let appBackgroundPrimary = Color(red: 0.04, green: 0.08, blue: 0.11)
    public static let appBackgroundSecondary = Color(red: 0.03, green: 0.05, blue: 0.08)
    public static let surfaceCard = Color(red: 0.11, green: 0.15, blue: 0.18)
    public static let surfaceElevated = Color(red: 0.15, green: 0.19, blue: 0.23)
    public static let borderMuted = Color.white.opacity(0.13)

    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.76)
    public static let textMuted = Color.white.opacity(0.50)

    public static let statusLive = Color(red: 1.00, green: 0.34, blue: 0.26)
    public static let statusFinal = Color(red: 0.58, green: 0.64, blue: 0.73)
    public static let statusDelayed = Color(red: 1.00, green: 0.75, blue: 0.22)
    public static let statusScheduled = Color(red: 0.27, green: 0.69, blue: 0.96)

    public static let success = Color(red: 0.18, green: 0.82, blue: 0.58)
    public static let warning = statusDelayed
    public static let danger = statusLive
}
