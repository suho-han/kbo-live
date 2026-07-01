import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
#if canImport(KboLiveCore)
import KboLiveCore
#endif
#if canImport(KboLiveDesignSystem)
import KboLiveDesignSystem
#endif
#if canImport(KboLiveFeatures)
import KboLiveFeatures
#endif

struct AppSettingsView: View {
    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var settings: BackendSettingsModel
    @ObservedObject var updateChecker: AppUpdateCheckModel
    @Binding var appearanceMode: KboAppearanceMode
    let onApplyBackendSettings: () -> Void

    var body: some View {
        TabView {
            BackendSettingsView(
                settings: settings,
                onApply: onApplyBackendSettings
            )
            .tabItem {
                Label("백엔드", systemImage: "server.rack")
            }

            teamSettingsView
                .tabItem {
                    Label("응원팀", systemImage: "star")
                }

            appearanceSettingsView
                .tabItem {
                    Label("표시", systemImage: "circle.lefthalf.filled")
                }

            updateSettingsView
                .tabItem {
                    Label("업데이트", systemImage: "arrow.down.circle")
                }
        }
    }

    private var teamSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                teamSettingsHeader

                LazyVGrid(columns: teamGridColumns, spacing: 10) {
                    TeamClearSelectionCard(
                        isSelected: viewModel.selectedTeamID == nil
                    ) {
                        viewModel.selectTeam(nil)
                    }

                    ForEach(viewModel.allTeams) { team in
                        TeamSelectionCard(
                            team: team,
                            isSelected: viewModel.selectedTeamID == team.id
                        ) {
                            viewModel.selectTeam(team.id)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(settingsBackground)
    }

    private var appearanceSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                KboCommandBar(
                    eyebrow: "Display",
                    title: "화면 모드",
                    subtitle: "앱의 배경색과 글자색을 다크, 화이트, 시스템 설정에 맞춰 전환합니다."
                ) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(KboSemanticColorToken.accentBlue)
                        .frame(width: 44, height: 44)
                        .background(KboSemanticColorToken.accentBlue.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } actions: {
                    Text(appearanceMode.title)
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.primaryText)
                        .padding(.horizontal, KboSpacingToken.medium)
                        .padding(.vertical, KboSpacingToken.small)
                        .background(KboSurfaceToken.glassControl)
                        .clipShape(Capsule())
                }

                KboGlassPanel(style: .card, cornerRadius: 22) {
                    Picker("화면 모드", selection: $appearanceMode) {
                        ForEach(KboAppearanceMode.allCases) { mode in
                            Label(mode.title, systemImage: systemImage(for: mode))
                                .tag(mode)
                        }
                    }
#if os(macOS)
                    .pickerStyle(.radioGroup)
#else
                    .pickerStyle(.segmented)
#endif
                    .foregroundStyle(KboTheme.primaryText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .background(settingsBackground)
    }

    private var teamGridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 210), spacing: 10),
            GridItem(.flexible(minimum: 210), spacing: 10)
        ]
    }

    private var teamSettingsHeader: some View {
        let selectedTeam = viewModel.selectedTeam
        let accentColor = selectedTeam.map { TeamColorResolver.color(forTeamID: $0.id) } ?? KboSemanticColorToken.accentBlue

        return KboGlassPanel(style: .navigation, cornerRadius: 22) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor.opacity(0.22))

                    Image(systemName: selectedTeam == nil ? "star" : "star.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 5) {
                    Text("응원팀")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(KboTheme.primaryText)

                    Text(selectedTeam.map { "\($0.name) 중심으로 경기와 알림을 정렬합니다." } ?? "응원팀을 고르면 오늘 화면과 메뉴바에서 먼저 보여줍니다.")
                        .font(KboTypographyToken.footnote)
                        .foregroundStyle(KboTheme.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if let selectedTeam {
                    TeamBadgeView(
                        shortName: selectedTeam.name,
                        fullName: selectedTeam.id,
                        accentColor: accentColor,
                        emphasis: .highlighted,
                        fixedWidth: 88,
                        logoSize: 22,
                        nameWidth: 34
                    )
                }
            }
            .padding(16)
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

    private var updateSettingsView: some View {
        Form {
            Section {
                LabeledContent("마지막 확인", value: updateChecker.lastCheckedText)

                LabeledContent("상태") {
                    updateStatusLabel
                }

                Button {
                    Task {
                        await updateChecker.checkForUpdates()
                    }
                } label: {
                    Label("업데이트 확인", systemImage: "arrow.clockwise")
                }
                .disabled(updateChecker.state == .checking)
            } header: {
                Text("버전 업데이트")
            }
        }
        .formStyle(.grouped)
    }

    private func systemImage(for mode: KboAppearanceMode) -> String {
        switch mode {
        case .system:
            return "desktopcomputer"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    @ViewBuilder
    private var updateStatusLabel: some View {
        switch updateChecker.state {
        case .idle:
            Text("미확인")
                .foregroundStyle(.secondary)
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .upToDate:
            Label("최신 버전", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .updateAvailable(let title):
            HStack(spacing: 8) {
                Label(title, systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)

                Button("열기") {
                    updateChecker.openReleasePage()
                }
            }
        case .noPublishedRelease:
            HStack(spacing: 8) {
                Label("공개 릴리스 없음", systemImage: "info.circle.fill")
                    .foregroundStyle(.secondary)

                Button("열기") {
                    updateChecker.openReleasePage()
                }
            }
        case .failed(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}

private struct TeamClearSelectionCard: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(KboSurfaceToken.glassControl)

                    Image(systemName: "slash.circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(KboTheme.secondaryText)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text("선택 안 함")
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)

                    Text("전체 경기 기준")
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)
                }

                Spacer(minLength: 0)

                selectionMark
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(KboSurfaceToken.card.opacity(isSelected ? 0.92 : 0.62))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? KboSurfaceToken.focusBorder : KboSurfaceToken.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectionMark: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(KboSemanticColorToken.accentMint)
        }
    }
}

private struct TeamSelectionCard: View {
    let team: KboTeamOption
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        TeamColorResolver.color(forTeamID: team.id)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                teamLogo

                VStack(alignment: .leading, spacing: 2) {
                    Text(team.koreanFullName)
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                selectionMark
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? accentColor.opacity(0.82) : KboSurfaceToken.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            }
            .shadow(color: isSelected ? accentColor.opacity(0.20) : .clear, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var teamLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accentColor.opacity(isSelected ? 0.24 : 0.14))

            TeamLogoImage(teamID: team.id)
                .frame(width: 34, height: 34)
        }
        .frame(width: 48, height: 48)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(isSelected ? 0.72 : 0.38), lineWidth: isSelected ? 1.5 : 1)
        }
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                accentColor.opacity(isSelected ? 0.28 : 0.12),
                KboSurfaceToken.card.opacity(isSelected ? 0.92 : 0.68)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var selectionMark: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentColor)
        }
    }
}

private struct TeamLogoImage: View {
    let teamID: String

    var body: some View {
        if let image = loadPlatformImage(named: teamID) {
            image
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(TeamColorResolver.color(forTeamID: teamID))
        }
    }

    private func loadPlatformImage(named teamID: String) -> Image? {
#if canImport(AppKit)
        if let image = NSImage(named: teamID) {
            return Image(nsImage: image)
        }
#elseif canImport(UIKit)
        if let image = UIImage(named: teamID) {
            return Image(uiImage: image)
        }
#endif

        let logoURL = Bundle.main.url(forResource: teamID, withExtension: "png")
        ?? Bundle.main.url(forResource: teamID, withExtension: "png", subdirectory: "TeamLogos")

        guard let logoURL else { return nil }

#if canImport(AppKit)
        if let image = NSImage(contentsOf: logoURL) {
            return Image(nsImage: image)
        }
#elseif canImport(UIKit)
        if let image = UIImage(contentsOfFile: logoURL.path()) {
            return Image(uiImage: image)
        }
#endif

        return nil
    }
}
