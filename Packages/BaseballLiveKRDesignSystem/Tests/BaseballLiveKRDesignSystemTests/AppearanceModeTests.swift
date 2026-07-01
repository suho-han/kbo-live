import SwiftUI
import Testing
@testable import BaseballLiveKRDesignSystem

struct AppearanceModeTests {
    @Test func systemIsTheDefaultAndUsesSystemColorScheme() {
        #expect(KboAppearanceMode.defaultValue == .system)
        #expect(KboAppearanceMode(rawValue: "unknown") == nil)
        #expect(KboAppearanceMode.resolved(from: "unknown") == .system)
        #expect(KboAppearanceMode.resolved(from: nil) == .system)
        #expect(KboAppearanceMode.system.preferredColorScheme == nil)
    }

    @Test func explicitModesMapToSwiftUIColorSchemeAndLabels() {
        #expect(KboAppearanceMode.dark.rawValue == "dark")
        #expect(KboAppearanceMode.dark.title == "다크 모드")
        #expect(KboAppearanceMode.dark.preferredColorScheme == ColorScheme.dark)

        #expect(KboAppearanceMode.light.rawValue == "light")
        #expect(KboAppearanceMode.light.title == "화이트 모드")
        #expect(KboAppearanceMode.light.preferredColorScheme == ColorScheme.light)

        #expect(KboAppearanceMode.system.rawValue == "system")
        #expect(KboAppearanceMode.system.title == "시스템 설정")
    }
}
