import SwiftUI

struct BackendPresetRow: View {
    @ObservedObject var settings: BackendSettingsModel
    let preset: BackendSettingsModel.BackendPreset

    private var isSelectable: Bool {
        settings.isPresetSelectable(preset)
    }

    private var isSelected: Bool {
        settings.selectedPreset == preset
    }

    var body: some View {
        Button {
            if settings.selectPreset(preset) {
                Task {
                    await settings.checkHealth()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? KboSemanticColorToken.accentMint : KboTheme.secondaryText)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.title)
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)

                    Text(preset.description)
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)

                    Text(settings.baseURLDescription(for: preset))
                        .font(.caption2.monospaced())
                        .foregroundStyle(settings.hasConfiguredBaseURL(for: preset) ? KboTheme.mutedText : KboSemanticColorToken.danger)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }
            .padding(KboSpacingToken.medium)
            .background(
                isSelected
                    ? KboSemanticColorToken.accentMint.opacity(0.14)
                    : KboSurfaceToken.glassControl
            )
            .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous)
                    .stroke(
                        isSelected
                            ? KboSemanticColorToken.accentMint.opacity(0.55)
                            : KboSurfaceToken.glassBorder.opacity(0.68),
                        lineWidth: 1
                    )
            }
            .opacity(isSelectable ? 1 : 0.52)
        }
        .disabled(isSelectable == false)
        .buttonStyle(.plain)
    }
}
