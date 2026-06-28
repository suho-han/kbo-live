import SwiftUI
import Foundation
#if canImport(AppKit)
import AppKit
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

struct MenuBarDashboardView: View {
    private enum Layout {
        static let popoverWidth: CGFloat = 340
        static let contentPadding = KboSpacingToken.large
        static let sectionSpacing: CGFloat = 14
        static let controlSpacing = KboSpacingToken.small
        static let cardPadding: CGFloat = 14
        static let cardCornerRadius = KboRadiusToken.large
        static let controlCornerRadius = KboRadiusToken.medium
        static let compactControlHeight: CGFloat = 54
        static let controlColumns = [
            GridItem(.flexible(), spacing: KboSpacingToken.small),
            GridItem(.flexible(), spacing: KboSpacingToken.small)
        ]
    }

    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var navigationModel: AppNavigationModel
    @Environment(\.openWindow) private var openWindow
    @State private var backendStatus: BackendServerStatus = .checking
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            headerSection

            if let game = viewModel.favoriteGame {
                favoriteGameCard(game)
            } else if let summary = currentSummary {
                fallbackSummary(summary)
            } else {
                emptySummary
            }

            backendIssueCallout

            LazyVGrid(columns: Layout.controlColumns, spacing: Layout.controlSpacing) {
                Button {
                    refreshAll()
                } label: {
                    compactActionButton(
                        title: isRefreshing ? "갱신 중" : "새로고침",
                        systemImage: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise"
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)

                SettingsLink {
                    compactActionButton(title: "설정", systemImage: "gearshape")
                }
                .buttonStyle(.plain)

                Button {
                    openWindow(id: "main-window")
                } label: {
                    compactActionButton(title: "메인으로", systemImage: "macwindow")
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await refreshBackendStatus()
                    }
                } label: {
                    compactStatusButton
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

            Text(lastUpdatedStatusText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KboTheme.secondaryText)
                .lineLimit(1)
        }
        .padding(Layout.contentPadding)
        .frame(width: Layout.popoverWidth)
        .background(KboSurfaceToken.contentBackground.opacity(0.94))
        .task {
            await viewModel.loadIfNeeded()
            await monitorBackendStatus()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("크보 라이브")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(KboTheme.primaryText)

                Text("/")
                    .font(.headline)
                    .foregroundStyle(KboTheme.secondaryText)

                Text(headerSubtitle)
                    .font(.headline.weight(.regular))
                    .foregroundStyle(headerAccentColor)
            }

            Spacer(minLength: 12)

            if viewModel.isLoading || isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func favoriteGameCard(_ game: Game) -> some View {
        Button {
            openInMainWindow(game)
        } label: {
            MenuBarFeaturedGameCardView(
                game: game,
                headline: "나의 팀 경기",
                favoriteTeamID: viewModel.selectedTeamID
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func fallbackSummary(_ summary: MenuBarGameSummary) -> some View {
        Button {
            if let game = viewModel.leagueGames.first {
                openInMainWindow(game)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.primaryText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KboTheme.primaryText)

                if let secondaryText = summary.secondaryText {
                    Text(secondaryText)
                        .font(.caption)
                        .foregroundStyle(KboTheme.secondaryText)
                }

                if let recentPlay = summary.recentPlay {
                    recentPlayLabel(recentPlay)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(KboSpacingToken.medium)
            .background(KboSurfaceToken.glassControl)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .stroke(KboSurfaceToken.glassBorder.opacity(0.7), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var emptySummary: some View {
        KboEmptyStateView(
            title: "오늘은 경기가 없습니다.",
            message: "다른 날짜를 조회하거나 새로고침해 경기 편성 변경을 확인할 수 있습니다.",
            systemImage: "calendar.badge.exclamationmark",
            style: .control
        )
    }

    private func recentPlayLabel(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KboTheme.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "quote.bubble.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(KboColorToken.statusLive)
        }
        .labelStyle(.titleAndIcon)
    }

    private var headerSubtitle: String {
        if let selectedTeam = viewModel.selectedTeam {
            return selectedTeam.koreanFullName
        }

        return "응원팀 미선택"
    }

    private func openInMainWindow(_ game: Game) {
        navigationModel.present(game: game)
        openWindow(id: "main-window")
    }

    private var currentSummary: MenuBarGameSummary? {
        viewModel.visibleGames.first.map(MenuBarGameSummaryMapper.map)
    }

    private var lastUpdatedStatusText: String {
        guard let lastUpdatedAt = viewModel.lastUpdatedAt else {
            return "마지막 갱신 대기 중"
        }

        return "마지막 갱신 \(Self.lastUpdatedFormatter.string(from: lastUpdatedAt))"
    }

    @ViewBuilder
    private var backendIssueCallout: some View {
        if backendStatus.needsSettingsCTA {
            SettingsLink {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(backendStatus.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Backend URL 확인")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KboTheme.primaryText)

                        Text(backendStatus.helpText)
                            .font(.caption2)
                            .foregroundStyle(KboTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(KboTheme.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(backendStatus.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Layout.controlCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.controlCornerRadius, style: .continuous)
                        .stroke(backendStatus.color.opacity(0.35), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func compactActionButton(title: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(KboTheme.primaryText.opacity(0.88))
                .frame(height: 16)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KboTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: Layout.compactControlHeight)
        .background(KboSurfaceToken.glassControl)
        .clipShape(RoundedRectangle(cornerRadius: Layout.controlCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Layout.controlCornerRadius, style: .continuous)
                .stroke(KboSurfaceToken.glassBorder.opacity(0.68), lineWidth: 1)
        }
    }

    private var compactStatusButton: some View {
        VStack(spacing: 6) {
            Image(systemName: backendStatus.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(backendStatus.color)
                .frame(height: 16)

            Text(backendStatus.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(KboTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: Layout.compactControlHeight)
        .background(backendStatus.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Layout.controlCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Layout.controlCornerRadius, style: .continuous)
                .stroke(backendStatus.color.opacity(0.35), lineWidth: 1)
        }
        .help(backendStatus.helpText)
    }

    private func refreshAll() {
        guard isRefreshing == false else { return }
        isRefreshing = true

        Task {
            await viewModel.refresh()
            await refreshBackendStatus()
            isRefreshing = false
        }
    }

    private func refreshBackendStatus() async {
        guard let healthURL = backendHealthURL else {
            backendStatus = .notConfigured
            return
        }

        backendStatus = .checking

        do {
            var request = URLRequest(url: healthURL)
            request.timeoutInterval = 1.5
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode) {
                backendStatus = .active
            } else {
                backendStatus = .inactive
            }
        } catch {
            backendStatus = .inactive
        }
    }

    private func monitorBackendStatus() async {
        while Task.isCancelled == false {
            await refreshBackendStatus()

            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                return
            }
        }
    }

    private var backendHealthURL: URL? {
        BackendSettingsModel.backendURL(baseURL: AppRuntime.backendBaseURL, path: "ready")
    }

    private var headerAccentColor: Color {
        guard let selectedTeamID = viewModel.selectedTeamID else {
            return .secondary
        }

        return teamColor(for: selectedTeamID)
    }

    private func teamColor(for teamID: String) -> Color {
#if canImport(KboLiveDesignSystem)
        TeamColorResolver.color(forTeamID: teamID)
#else
        .secondary
#endif
    }

    private static let lastUpdatedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

private struct MenuBarFeaturedGameCardView: View {
    let game: Game
    let headline: String
    let favoriteTeamID: String?
    @Environment(\.kboFontScale) private var fontScale

    private enum Layout {
        static let badgeWidth: CGFloat = 86
        static let nameWidth: CGFloat = 30
        static let logoSize: CGFloat = 16
        static let scoreWidth: CGFloat = 30
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(headline)
                    .font(KboTypographyToken.caption(scaledBy: fontScale))
                    .foregroundStyle(KboColorToken.statusLive)

                Spacer(minLength: 8)

                Text(gameDateVenueText)
                    .font(KboTypographyToken.caption(scaledBy: fontScale))
                    .foregroundStyle(KboTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KboTheme.secondaryText)
            }

            HStack(alignment: .top, spacing: 8) {
                teamColumn(
                    team: game.awayTeam,
                    score: game.score.away,
                    isFavorite: game.awayTeam.id == favoriteTeamID,
                    probablePitcher: trimmedPitcherName(game.probablePitchers.away)
                )

                Spacer(minLength: 0)

                centerGameState

                Spacer(minLength: 0)

                teamColumn(
                    team: game.homeTeam,
                    score: game.score.home,
                    isFavorite: game.homeTeam.id == favoriteTeamID,
                    probablePitcher: trimmedPitcherName(game.probablePitchers.home)
                )
            }

            if let recentPlay = GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 48) {
                recentPlayLabel(recentPlay)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(KboTheme.cardBackground.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func teamColumn(team: Team, score: Int, isFavorite: Bool, probablePitcher: String?) -> some View {
        VStack(spacing: 7) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: isFavorite ? .highlighted : .normal,
                fixedWidth: Layout.badgeWidth,
                logoSize: Layout.logoSize,
                nameWidth: Layout.nameWidth
            )

            if let probablePitcher {
                Text(probablePitcher)
                    .font(KboTypographyToken.system(size: 11, weight: .semibold, scaledBy: fontScale))
                    .foregroundStyle(KboTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: Layout.badgeWidth, alignment: .center)
            }

            if game.status != .scheduled {
                Text(String(score))
                    .font(KboTypographyToken.system(size: 18, weight: .black, scaledBy: fontScale))
                    .monospacedDigit()
                    .foregroundStyle(isFavorite ? TeamColorResolver.color(forTeamID: team.id) : KboTheme.primaryText)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: Layout.scoreWidth, alignment: .center)
            }
        }
        .frame(width: Layout.badgeWidth, alignment: .center)
    }

    private var centerGameState: some View {
        VStack(spacing: 7) {
            Text("VS")
                .font(KboTypographyToken.system(size: 12, weight: .bold, scaledBy: fontScale))
                .foregroundStyle(KboTheme.secondaryText)

            if game.status == .live, game.count != nil || game.bases != nil || game.inning != nil {
                MenuBarGameStateBlockView(
                    inning: game.inning,
                    count: game.count,
                    bases: game.bases
                )
            }
        }
        .frame(width: 96, alignment: .center)
    }

    private func trimmedPitcherName(_ name: String?) -> String? {
        guard let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmedName.isEmpty == false else {
            return nil
        }

        return trimmedName
    }

    private func recentPlayLabel(_ text: String) -> some View {
        Label {
            Text(text)
                .font(KboTypographyToken.system(size: 11, weight: .semibold, scaledBy: fontScale))
                .foregroundStyle(KboTheme.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "quote.bubble.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(KboColorToken.statusLive)
        }
        .labelStyle(.titleAndIcon)
    }

    private var gameDateVenueText: String {
        let time = game.startTime.map { Self.cardTimeFormatter.string(from: $0) } ?? "시간 미정"
        let venue = game.venue?.trimmingCharacters(in: .whitespacesAndNewlines)
        let venueText = venue?.isEmpty == false ? venue : nil

        guard let date = Self.gameDateFormatter.date(from: game.date) else {
            return [time, venueText].compactMap(\.self).joined(separator: " · ")
        }

        return [Self.cardDateFormatter.string(from: date), time, venueText].compactMap(\.self).joined(separator: " · ")
    }

    private static let gameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M.d"
        return formatter
    }()

    private static let cardTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct MenuBarGameStateBlockView: View {
    let inning: InningState?
    let count: CountState?
    let bases: BasesState?

    var body: some View {
        VStack(spacing: 6) {
            if let inning {
                inningIndicator(inning)
            }

            if let count {
                VStack(alignment: .leading, spacing: 4) {
                    countRow(label: "B", value: count.balls, total: 3, color: KboColorToken.success)
                    countRow(label: "S", value: count.strikes, total: 2, color: KboColorToken.warning)
                    countRow(label: "O", value: count.outs, total: 2, color: KboColorToken.danger)
                }
            }

            if let bases {
                BaseDiamondView(
                    firstOccupied: bases.first,
                    secondOccupied: bases.second,
                    thirdOccupied: bases.third
                )
                .frame(width: 31, height: 24)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(width: 92)
        .background(Color.black.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1)
        }
        .fixedSize(horizontal: true, vertical: true)
    }

    private func inningIndicator(_ inning: InningState) -> some View {
        HStack(spacing: 3) {
            Text(String(inning.number))
                .monospacedDigit()

            Text(inning.half == .top ? "▲" : "▼")
                .font(.system(size: 7, weight: .black))
                .baselineOffset(0.5)
        }
        .font(.system(size: 10, weight: .black))
        .foregroundStyle(KboColorToken.statusScheduled)
        .lineLimit(1)
    }

    private func countRow(label: String, value: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(KboTheme.secondaryText)
                .frame(width: 7, alignment: .leading)

            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < clamped(value, total: total) ? color : color.opacity(0.18))
                    .frame(width: 5.5, height: 5.5)
                    .overlay {
                        Circle()
                            .stroke(color.opacity(0.45), lineWidth: 0.7)
                    }
            }
        }
    }

    private func clamped(_ value: Int, total: Int) -> Int {
        min(max(value, 0), total)
    }
}

private enum BackendServerStatus {
    case checking
    case active
    case inactive
    case notConfigured

    var title: String {
        switch self {
        case .checking:
            return "확인 중"
        case .active:
            return "서버 ON"
        case .inactive:
            return "서버 OFF"
        case .notConfigured:
            return "서버 미설정"
        }
    }

    var systemImage: String {
        switch self {
        case .checking:
            return "arrow.clockwise"
        case .active:
            return "checkmark.circle.fill"
        case .inactive:
            return "xmark.circle.fill"
        case .notConfigured:
            return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .checking:
            return .secondary
        case .active:
            return .green
        case .inactive:
            return .red
        case .notConfigured:
            return .orange
        }
    }

    var helpText: String {
        switch self {
        case .checking:
            return "백엔드 서버 상태를 확인하고 있습니다."
        case .active:
            return "백엔드 서버가 응답 중입니다."
        case .inactive:
            return "백엔드 서버가 응답하지 않습니다."
        case .notConfigured:
            return "KBO_LIVE_BASE_URL이 설정되지 않았습니다."
        }
    }

    var needsSettingsCTA: Bool {
        switch self {
        case .inactive, .notConfigured:
            return true
        case .checking, .active:
            return false
        }
    }
}
