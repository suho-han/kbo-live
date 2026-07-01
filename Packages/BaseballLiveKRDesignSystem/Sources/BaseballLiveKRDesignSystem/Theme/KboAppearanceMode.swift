import SwiftUI

public enum KboAppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public static let storageKey = "kboLiveAppearanceMode"
    public static let defaultValue = KboAppearanceMode.system

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system:
            return "시스템 설정"
        case .light:
            return "화이트 모드"
        case .dark:
            return "다크 모드"
        }
    }

    public var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    public static func resolved(from rawValue: String?) -> KboAppearanceMode {
        rawValue.flatMap(KboAppearanceMode.init(rawValue:)) ?? defaultValue
    }
}
