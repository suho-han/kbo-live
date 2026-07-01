import SwiftUI

public enum KboTypographyToken {
    public static let caption = Font.system(size: 11, weight: .medium)
    public static let footnote = Font.system(size: 13, weight: .medium)
    public static let body = Font.system(size: 15, weight: .regular)
    public static let headline = Font.system(size: 17, weight: .semibold)
    public static let scoreCompact = Font.system(size: 24, weight: .bold)
    public static let scoreLarge = Font.system(size: 36, weight: .heavy)
    public static let menuBarCompact = Font.system(size: 13, weight: .bold)

    public static func caption(scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(11, by: scale), weight: .medium)
    }

    public static func footnote(scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(13, by: scale), weight: .medium)
    }

    public static func body(scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(15, by: scale), weight: .regular)
    }

    public static func headline(scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(17, by: scale), weight: .semibold)
    }

    public static func scoreCompact(scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(24, by: scale), weight: .bold)
    }

    public static func scoreLarge(scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(36, by: scale), weight: .heavy)
    }

    public static func menuBarCompact(scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(13, by: scale), weight: .bold)
    }

    public static func system(size: CGFloat, weight: Font.Weight, scaledBy scale: CGFloat) -> Font {
        .system(size: scaledSize(size, by: scale), weight: weight)
    }

    private static func scaledSize(_ size: CGFloat, by scale: CGFloat) -> CGFloat {
        size * KboFontScale.clamped(scale)
    }
}

public enum KboFontScale {
    public static let minimum: CGFloat = 0.85
    public static let maximum: CGFloat = 1.35
    public static let defaultValue: CGFloat = 1.0
    public static let step: CGFloat = 0.05

    public static func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, minimum), maximum)
    }
}

private struct KboFontScaleKey: EnvironmentKey {
    static let defaultValue = KboFontScale.defaultValue
}

public extension EnvironmentValues {
    var kboFontScale: CGFloat {
        get { self[KboFontScaleKey.self] }
        set { self[KboFontScaleKey.self] = KboFontScale.clamped(newValue) }
    }
}
