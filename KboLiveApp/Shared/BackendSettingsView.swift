import SwiftUI

struct BackendSettingsView: View {
    @ObservedObject var settings: BackendSettingsModel
    @State private var hasCheckedHealth = false
    let onApply: () -> Void

    var body: some View {
        Form {
            Section {
                presetButton(.local)
                presetButton(.production)

                if settings.isEnvironmentOverridden {
                    Text("KBO_LIVE_BASE_URL 환경변수가 우선 적용 중입니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("환경 (준비중)")
            } footer: {
                Text("Production URL은 기본값 또는 KBO_LIVE_PRODUCTION_BASE_URL 환경변수로 설정됩니다.")
            }

            Section {
                LabeledContent("상태") {
                    statusLabel
                }

                HStack {
                    Button("기본값") {
                        settings.reset()
                        onApply()
                    }

                    Spacer()

                    Button("적용") {
                        if settings.save() {
                            onApply()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(settings.isEnvironmentOverridden)
                }
            }
        }
        .formStyle(.grouped)
        .task {
            guard hasCheckedHealth == false else { return }
            hasCheckedHealth = true
            await settings.checkHealth()
        }
    }

    private func presetButton(_ preset: BackendSettingsModel.BackendPreset) -> some View {
        Button {
            settings.selectPreset(preset)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: settings.selectedPreset == preset ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(settings.selectedPreset == preset ? .green : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.title)
                        .font(.headline)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(settings.baseURLDescription(for: preset))
                        .font(.caption2.monospaced())
                        .foregroundStyle(settings.hasConfiguredBaseURL(for: preset) ? Color.secondary : Color.red)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .disabled(settings.isEnvironmentOverridden)
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch settings.validationState {
        case .idle:
            Text("미확인")
                .foregroundStyle(.secondary)
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .available:
            Label("연결됨", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .unavailable(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}
