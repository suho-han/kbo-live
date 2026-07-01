import SwiftUI
#if canImport(KboLiveDesignSystem)
import KboLiveDesignSystem
#endif

@main
struct KboLiveiOSApp: App {
    @AppStorage(KboAppearanceMode.storageKey) private var appearanceModeRawValue = KboAppearanceMode.defaultValue.rawValue

    var body: some Scene {
        WindowGroup {
            KboLiveHomeRootView(appearanceMode: appearanceModeBinding)
                .preferredColorScheme(appearanceMode.preferredColorScheme)
        }
    }

    private var appearanceMode: KboAppearanceMode {
        KboAppearanceMode.resolved(from: appearanceModeRawValue)
    }

    private var appearanceModeBinding: Binding<KboAppearanceMode> {
        Binding {
            KboAppearanceMode.resolved(from: appearanceModeRawValue)
        } set: { newValue in
            appearanceModeRawValue = newValue.rawValue
        }
    }
}
