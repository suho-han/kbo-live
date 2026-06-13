import SwiftUI
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
    @ObservedObject var viewModel: TodayGamesViewModel
    @ObservedObject var navigationModel: AppNavigationModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            if let game = viewModel.favoriteGame {
                favoriteGameCard(game)
            } else if let summary = currentSummary {
                fallbackSummary(summary)
            } else {
                emptySummary
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                SettingsLink {
                    actionRow(title: "설정", systemImage: "gearshape")
                }
                .buttonStyle(.plain)

                Button {
                    openWindow(id: "main-window")
                } label: {
                    actionRow(title: "앱 창 열기", systemImage: "macwindow")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 340)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("크보 라이브")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)

                Text("/")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(headerSubtitle)
                    .font(.headline.weight(.regular))
                    .foregroundStyle(headerAccentColor)
            }

            Spacer(minLength: 12)

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func favoriteGameCard(_ game: Game) -> some View {
        Button {
            openInMainWindow(game)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        teamScoreRow(team: game.awayTeam, score: game.score.away)
                        teamScoreRow(team: game.homeTeam, score: game.score.home)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                Text(primaryMetaText(for: game))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let secondaryMetaText = secondaryMetaText(for: game) {
                    Text(secondaryMetaText)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.88))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        featuredCardAccentColor(for: game).opacity(0.26),
                        featuredCardAccentColor(for: game).opacity(0.10),
                        Color.primary.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(featuredCardAccentColor(for: game).opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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

                if let secondaryText = summary.secondaryText {
                    Text(secondaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var emptySummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("오늘 표시할 경기가 없습니다.")
                .font(.subheadline.weight(.semibold))

            Text("설정에서 응원팀을 바꾸면 다른 경기를 바로 확인할 수 있습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var headerSubtitle: String {
        if let selectedTeam = viewModel.selectedTeam {
            return fullTeamName(for: selectedTeam)
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

    private func teamScoreRow(team: Team, score: Int) -> some View {
        HStack(spacing: 10) {
            teamBadge(for: team)

            Spacer(minLength: 8)

            scoreText(score, color: scoreColor(for: team.id))
        }
    }

    @ViewBuilder
    private func scoreText(_ score: Int, color: Color) -> some View {
#if canImport(KboLiveDesignSystem)
        ScoreDigitsView(score: score, mode: .menuBarCompact)
            .foregroundStyle(color)
#else
        Text(String(score))
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
#endif
    }

    private func actionRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(headerAccentColor.opacity(0.85))
                .frame(width: 16)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func teamBadge(for team: Team) -> some View {
        HStack(spacing: 8) {
            teamMark(for: team)

            Text(team.name)
                .font(.subheadline.weight(.semibold))
                .tracking(-0.1)
                .foregroundStyle(teamTextColor(for: team.id))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 112, alignment: .leading)
        .background(teamColor(for: team.id).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(teamColor(for: team.id).opacity(0.55), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func teamMark(for team: Team) -> some View {
        if let teamLogoImage = teamLogoImage(for: team.id) {
            teamLogoImage
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        } else {
            Text(teamMarkText(for: team.id))
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(teamColor(for: team.id))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    private func primaryMetaText(for game: Game) -> String {
        let parts = [
            GameProjectionFormatter.statusLabelText(for: game.status),
            GameProjectionFormatter.inningText(for: game),
            game.status == .live ? GameProjectionFormatter.outCountText(for: game.count?.outs) : nil,
            game.venue
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .reduce(into: [String]()) { partialResult, part in
                if partialResult.contains(part) == false {
                    partialResult.append(part)
                }
            }

        return parts.isEmpty ? statusText(for: game) : parts.joined(separator: " · ")
    }

    private func secondaryMetaText(for game: Game) -> String? {
        if let recentPlay = GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 56) {
            return recentPlay
        }

        if isPastGameDate(game.date) {
            return "종료"
        }

        if let startTime = game.startTime {
            return startTime.formatted(.dateTime.hour().minute()) + " 시작 예정"
        }

        return nil
    }

    private var headerAccentColor: Color {
        guard let selectedTeamID = viewModel.selectedTeamID else {
            return .secondary
        }

        return teamColor(for: selectedTeamID)
    }

    private func featuredCardAccentColor(for game: Game) -> Color {
        if let selectedTeamID = viewModel.selectedTeamID,
           game.involves(teamID: selectedTeamID) {
            return teamColor(for: selectedTeamID)
        }

        return teamColor(for: game.homeTeam.id)
    }

    private func teamTextColor(for teamID: String) -> Color {
        if let selectedTeamID = viewModel.selectedTeamID,
           selectedTeamID == teamID {
            return teamColor(for: teamID)
        }

        return teamColor(for: teamID).opacity(0.92)
    }

    private func scoreColor(for teamID: String) -> Color {
        if let selectedTeamID = viewModel.selectedTeamID,
           selectedTeamID == teamID {
            return teamColor(for: teamID)
        }

        return .primary
    }

    private func teamColor(for teamID: String) -> Color {
#if canImport(KboLiveDesignSystem)
        TeamColorResolver.color(forTeamID: teamID)
#else
        .secondary
#endif
    }

    private func teamLogoImage(for teamID: String) -> Image? {
#if canImport(AppKit)
        let resourceName = teamLogoResourceName(for: teamID)

        if let image = NSImage(named: resourceName) {
            return Image(nsImage: image)
        }

        if let url = Bundle.main.url(forResource: resourceName, withExtension: "png", subdirectory: "TeamLogos"),
           let image = NSImage(contentsOf: url) {
            return Image(nsImage: image)
        }
#endif

        return nil
    }

    private func teamLogoResourceName(for teamID: String) -> String {
        switch teamID {
        case "LG", "OB", "KT", "NC", "WO", "SS", "LT", "HH", "HT":
            return teamID
        case "SK":
            return "SK"
        default:
            return teamID
        }
    }

    private func teamMarkText(for teamID: String) -> String {
        switch teamID {
        case "LG":
            return "LG"
        case "OB":
            return "두"
        case "SK":
            return "S"
        case "SS":
            return "삼"
        case "HT":
            return "K"
        case "KT":
            return "KT"
        case "LT":
            return "롯"
        case "HH":
            return "한"
        case "NC":
            return "N"
        case "WO":
            return "키"
        default:
            return String(teamID.prefix(1))
        }
    }

    private func statusText(for game: Game) -> String {
        switch game.status {
        case .live:
            return "진행 중"
        case .scheduled:
            return "경기 전"
        case .delayed:
            return "지연"
        case .final:
            return "종료"
        case .cancelled:
            return "취소"
        case .unknown:
            return "상태 확인 중"
        }
    }

    private func fullTeamName(for team: KboTeamOption) -> String {
        switch team.id {
        case "LG":
            return "LG 트윈스"
        case "OB":
            return "두산 베어스"
        case "SK":
            return "SSG 랜더스"
        case "SS":
            return "삼성 라이온즈"
        case "HT":
            return "기아 타이거즈"
        case "KT":
            return "KT 위즈"
        case "LT":
            return "롯데 자이언츠"
        case "HH":
            return "한화 이글스"
        case "NC":
            return "NC 다이노스"
        case "WO":
            return "키움 히어로즈"
        default:
            return team.name
        }
    }

    private func isPastGameDate(_ dateString: String) -> Bool {
        guard let gameDate = Self.gameDateFormatter.date(from: dateString) else {
            return false
        }

        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        return gameDate < today
    }

    private static let gameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
