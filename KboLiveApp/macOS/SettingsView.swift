import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var settings: BackendSettingsModel
    let onApplyBackendSettings: () -> Void

    var body: some View {
        AppSettingsView(
            viewModel: viewModel,
            settings: settings,
            onApplyBackendSettings: onApplyBackendSettings
        )
        .frame(width: 520, height: 430)
    }
}
