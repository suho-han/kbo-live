import SwiftUI

struct BackendSettingsView: View {
    private enum Layout {
        static let contentPadding = KboSpacingToken.large
        static let sectionSpacing = KboSpacingToken.large
        static let cardSpacing = KboSpacingToken.medium
        static let cardPadding = KboSpacingToken.large
        static let cardCornerRadius: CGFloat = 22
    }

    @ObservedObject var settings: BackendSettingsModel
    @State private var hasCheckedHealth = false
    let onApply: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                headerCard
                presetSection
                actionSection
            }
            .padding(Layout.contentPadding)
        }
        .background(settingsBackground)
        .task {
            guard hasCheckedHealth == false else { return }
            hasCheckedHealth = true
            await settings.checkHealth()
        }
    }

    private var headerCard: some View {
        KboCommandBar(
            eyebrow: "Backend",
            title: "서버 연결",
            subtitle: "앱, 위젯, 메뉴바가 사용할 Baseball LIVE KR backend preset을 선택합니다."
        ) {
            Image(systemName: "server.rack")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(statusAccentColor)
                .frame(width: 44, height: 44)
                .background(statusAccentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } actions: {
            statusBadge
        }
    }

    private var presetSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                sectionTitle("환경", subtitle: "Production이 기본값이며, Local과 Staging(Beta)는 계정 기능이 준비되기 전까지 잠깁니다.")

                VStack(spacing: KboSpacingToken.small) {
                    ForEach(settings.orderedPresets) { preset in
                        BackendPresetRow(settings: settings, preset: preset)
                    }
                }

                if settings.hasEnvironmentBaseURL {
                    Label("BASEBALL_LIVE_KR_BASE_URL 환경변수가 있으면 모든 preset보다 우선합니다.", systemImage: "info.circle.fill")
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboSemanticColorToken.warning)
                }
            }
        }
    }

    private var actionSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                HStack(spacing: KboSpacingToken.small) {
                    Text("연결 상태")
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)

                    Spacer(minLength: 0)

                    statusLabel
                }

                HStack(spacing: KboSpacingToken.small) {
                    Button {
                        settings.reset()
                        onApply()
                    } label: {
                        actionButtonLabel(title: "기본값", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await settings.checkHealth()
                        }
                    } label: {
                        actionButtonLabel(title: "상태 확인", systemImage: "wave.3.right.circle")
                    }
                    .buttonStyle(.plain)

                    KboPrimaryActionButton(
                        title: "적용",
                        systemImage: "checkmark.circle.fill",
                        tint: KboSemanticColorToken.accentBlue,
                        isDisabled: false
                    ) {
                        applySettings()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch settings.validationState {
        case .idle:
            Text("미확인")
                .foregroundStyle(KboTheme.secondaryText)
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .available:
            Label("연결됨", systemImage: "checkmark.circle.fill")
                .foregroundStyle(KboSemanticColorToken.success)
        case .unavailable(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(KboSemanticColorToken.danger)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusAccentColor)
                .frame(width: 8, height: 8)

            Text(statusBadgeText)
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.primaryText)
        }
        .padding(.horizontal, KboSpacingToken.medium)
        .padding(.vertical, KboSpacingToken.small)
        .background(statusAccentColor.opacity(0.14))
        .clipShape(Capsule())
    }

    private var statusBadgeText: String {
        switch settings.validationState {
        case .idle:
            return "대기"
        case .checking:
            return "확인 중"
        case .available:
            return "연결됨"
        case .unavailable:
            return "연결 실패"
        }
    }

    private var statusAccentColor: Color {
        switch settings.validationState {
        case .idle, .checking:
            return KboSemanticColorToken.accentBlue
        case .available:
            return KboSemanticColorToken.success
        case .unavailable:
            return KboSemanticColorToken.danger
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        KboGlassPanel(style: .card, cornerRadius: Layout.cardCornerRadius) {
            content()
                .padding(Layout.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            Text(subtitle)
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButtonLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))

            Text(title)
                .font(KboTypographyToken.caption)
                .lineLimit(1)
        }
        .foregroundStyle(KboTheme.primaryText)
        .frame(maxWidth: .infinity, minHeight: KboControlToken.primaryButtonHeight)
        .background(KboSurfaceToken.glassControl)
        .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KboRadiusToken.large, style: .continuous)
                .stroke(KboSurfaceToken.glassBorder.opacity(0.7), lineWidth: 1)
        }
    }

    private var settingsBackground: some View {
        LinearGradient(
            colors: [
                KboColorToken.appBackgroundTop,
                KboColorToken.appBackgroundPrimary,
                KboColorToken.appBackgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func applySettings() {
        if settings.save() {
            onApply()
            Task {
                await settings.checkHealth()
            }
        }
    }
}
