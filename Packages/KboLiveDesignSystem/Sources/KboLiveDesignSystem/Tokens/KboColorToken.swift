import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum KboColorToken {
    public static let backgroundPrimary = adaptive(light: RGB(0.94, 0.97, 0.99), dark: RGB(0.04, 0.07, 0.10))
    public static let backgroundSecondary = adaptive(light: RGB(0.88, 0.93, 0.96), dark: RGB(0.07, 0.11, 0.14))
    public static let appBackgroundTop = adaptive(light: RGB(0.90, 0.97, 0.98), dark: RGB(0.05, 0.13, 0.16))
    public static let appBackgroundPrimary = adaptive(light: RGB(0.96, 0.98, 0.99), dark: RGB(0.04, 0.08, 0.11))
    public static let appBackgroundSecondary = adaptive(light: RGB(0.86, 0.91, 0.95), dark: RGB(0.03, 0.05, 0.08))
    public static let surfaceCard = adaptive(light: RGB(1.00, 1.00, 1.00), dark: RGB(0.11, 0.15, 0.18))
    public static let surfaceElevated = adaptive(light: RGB(0.97, 0.99, 1.00), dark: RGB(0.15, 0.19, 0.23))
    public static let borderMuted = adaptive(light: RGB(0.71, 0.77, 0.84), dark: RGB(1.00, 1.00, 1.00)).opacity(0.32)
    public static let shadow = adaptive(light: RGB(0.05, 0.09, 0.13), dark: RGB(0.00, 0.00, 0.00))

    public static let textPrimary = adaptive(light: RGB(0.05, 0.09, 0.13), dark: RGB(1.00, 1.00, 1.00))
    public static let textSecondary = adaptive(light: RGB(0.27, 0.34, 0.42), dark: RGB(1.00, 1.00, 1.00)).opacity(0.76)
    public static let textMuted = adaptive(light: RGB(0.45, 0.51, 0.59), dark: RGB(1.00, 1.00, 1.00)).opacity(0.58)

    public static let statusLive = Color(red: 1.00, green: 0.34, blue: 0.26)
    public static let statusFinal = Color(red: 0.58, green: 0.64, blue: 0.73)
    public static let statusDelayed = Color(red: 1.00, green: 0.75, blue: 0.22)
    public static let statusScheduled = Color(red: 0.27, green: 0.69, blue: 0.96)

    public static let success = Color(red: 0.18, green: 0.82, blue: 0.58)
    public static let warning = statusDelayed
    public static let danger = statusLive

    private struct RGB {
        let red: Double
        let green: Double
        let blue: Double

        init(_ red: Double, _ green: Double, _ blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }

    private static func fixed(_ rgb: RGB) -> Color {
        Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    private static func adaptive(light: RGB, dark: RGB) -> Color {
#if canImport(AppKit)
        Color(NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            let selected = match == .darkAqua ? dark : light
            return NSColor(
                calibratedRed: selected.red,
                green: selected.green,
                blue: selected.blue,
                alpha: 1
            )
        })
#elseif canImport(UIKit)
        Color(UIColor { traits in
            let selected = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: selected.red,
                green: selected.green,
                blue: selected.blue,
                alpha: 1
            )
        })
#else
        fixed(dark)
#endif
    }
}
