import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
#if canImport(BaseballLiveKRCore)
import BaseballLiveKRCore
#endif
#if canImport(BaseballLiveKRDesignSystem)
import BaseballLiveKRDesignSystem
#endif

public enum LiveActivityControlState: Equatable {
    case unavailable
    case start
    case stop
}

public struct TodayGamesView: View {
    public enum Layout {
        public static let contentHorizontalPadding: CGFloat = 20
        public static let leagueCardMinimumWidth: CGFloat = 184
        public static let leagueGridSpacing: CGFloat = 12
        public static let leagueGridColumnCount = 5
        public static let leagueSectionWidth = leagueCardMinimumWidth * CGFloat(leagueGridColumnCount)
            + leagueGridSpacing * CGFloat(leagueGridColumnCount - 1)
        public static let minimumWindowWidth = leagueSectionWidth + contentHorizontalPadding * 2

        static let standingsTableWidth: CGFloat = 774
        static let commandBarWidth = standingsTableWidth
        static let favoriteInfoWidth: CGFloat = 236
        static let favoriteColumnSpacing: CGFloat = 14
        static let featuredGameWidth: CGFloat = standingsTableWidth - favoriteInfoWidth - favoriteColumnSpacing
        static let favoriteBlockHeight: CGFloat = 250
    }

    @ObservedObject private var viewModel: TodayGamesViewModel
    @State private var selectedGame: Game?
    @Environment(\.kboFontScale) private var fontScale
    private let onOpenSettings: (() -> Void)?
    private let liveActivityState: ((Game) -> LiveActivityControlState)?
    private let onToggleLiveActivity: ((Game) -> Void)?

    public init(
        viewModel: TodayGamesViewModel,
        onOpenSettings: (() -> Void)? = nil,
        liveActivityState: ((Game) -> LiveActivityControlState)? = nil,
        onToggleLiveActivity: ((Game) -> Void)? = nil
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onOpenSettings = onOpenSettings
        self.liveActivityState = liveActivityState
        self.onToggleLiveActivity = onToggleLiveActivity
    }

    public var body: some View {
        NavigationStack {
            content
                .background(backgroundView)
                .navigationTitle("Baseball LIVE KR")
#if os(iOS)
                .toolbarBackground(.hidden, for: .navigationBar)
#endif
                .navigationDestination(item: $selectedGame) { game in
                    GameDetailScreen(parentViewModel: viewModel, game: game)
                }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch viewModel.state {
            case .idle where viewModel.games.isEmpty:
                loadingView
            case .loading where viewModel.games.isEmpty:
                loadingView
            case .failed(let message) where viewModel.games.isEmpty && viewModel.standings.isEmpty:
                failureView(message: message)
            default:
                GeometryReader { proxy in
                    let availableWidth = contentWidth(for: proxy.size.width)
                    let sectionWidth = sectionWidth(for: availableWidth)
                    let standingsWidth = standingsBlockWidth(for: availableWidth)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            commandBar(width: standingsWidth)
                            gamesFailureBanner
                            favoriteSection(availableWidth: availableWidth)
                            standingsSection(availableWidth: availableWidth)
                            leagueSection(sectionWidth: sectionWidth)
                        }
                        .frame(width: sectionWidth, alignment: .leading)
                        .padding(.horizontal, Layout.contentHorizontalPadding)
                        .padding(.vertical, 24)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }

    private func commandBar(width: CGFloat) -> some View {
        KboCommandBar(
            title: "Baseball LIVE KR",
            subtitle: commandBarSubtitle
        ) {
            Image(systemName: "baseball.fill")
                .font(KboTypographyToken.system(size: 21, weight: .bold, scaledBy: fontScale))
                .foregroundStyle(KboSemanticColorToken.accentMint)
                .frame(width: 44, height: 44)
                .background(KboSemanticColorToken.accentMint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } actions: {
            HStack(spacing: 8) {
                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    commandIcon(systemImage: viewModel.isLoading ? "arrow.clockwise.circle" : "arrow.clockwise", title: "새로고침")
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)

                if let onOpenSettings {
                    Button {
                        onOpenSettings()
                    } label: {
                        commandIcon(systemImage: "gearshape.fill", title: "설정")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: width, alignment: .leading)
    }


    private func favoriteSection(availableWidth: CGFloat) -> some View {
        let sectionWidth = min(Layout.standingsTableWidth, availableWidth)

        return VStack(alignment: .leading, spacing: 14) {
            favoriteSectionHeader

            if viewModel.selectedTeam != nil || viewModel.favoriteGame != nil {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Layout.favoriteColumnSpacing) {
                        favoriteInfoColumn
                            .frame(width: Layout.favoriteInfoWidth, alignment: .topLeading)
                            .frame(height: Layout.favoriteBlockHeight)

                        favoriteGameColumn
                            .frame(width: Layout.featuredGameWidth, alignment: .topLeading)
                            .frame(height: Layout.favoriteBlockHeight)
                    }
                    .frame(width: Layout.standingsTableWidth, alignment: .leading)

                    VStack(alignment: .leading, spacing: 14) {
                        favoriteInfoColumn
                            .frame(maxWidth: sectionWidth, alignment: .leading)
                        favoriteGameColumn
                            .frame(maxWidth: sectionWidth, alignment: .leading)
                    }
                    .frame(maxWidth: sectionWidth, alignment: .leading)
                }
            } else {
                emptyFavoriteView
            }
        }
        .frame(width: sectionWidth, alignment: .leading)
    }

    @ViewBuilder
    private var favoriteInfoColumn: some View {
        if let selectedTeam = viewModel.selectedTeam {
            MyTeamSummaryCardView(
                team: selectedTeam,
                record: selectedTeamRecord,
                game: viewModel.favoriteGame
            )
            .frame(maxHeight: .infinity)
        } else {
            emptyFavoriteView
        }
    }

    @ViewBuilder
    private var favoriteGameColumn: some View {
        if let game = viewModel.favoriteGame {
            VStack(spacing: 10) {
                Button {
                    selectedGame = game
                } label: {
                    FeaturedGameCardView(
                        game: game,
                        favoriteTeamID: viewModel.selectedTeamID
                    )
                    .frame(height: Layout.favoriteBlockHeight)
                }
                .buttonStyle(.plain)

                liveActivityButton(for: game)
            }
        } else {
            emptyFavoriteView
        }
    }

    private func leagueSection(sectionWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "리그 전체", subtitle: "진행 중 경기를 우선 정렬한 전체 경기 목록입니다.")
            filterPicker

            if case let .failed(message) = viewModel.state, viewModel.games.isEmpty {
                gamesFailureView(message: message)
            } else if viewModel.leagueGames.isEmpty, viewModel.games.isEmpty == false {
                emptyView
            } else {
                LazyVStack(alignment: .leading, spacing: 22) {
                    ForEach(groupedLeagueGames) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            dateSectionHeader(section)

                            if section.games.isEmpty {
                                noGamesTodayView
                            } else {
                                LazyVGrid(columns: leagueGridColumns, alignment: .leading, spacing: 12) {
                                    ForEach(section.games) { game in
                                        VStack(spacing: 8) {
                                            Button {
                                                selectedGame = game
                                            } label: {
                                                TodayGameCardView(
                                                    game: game,
                                                    favoriteTeamID: viewModel.selectedTeamID
                                                )
                                            }
                                            .buttonStyle(.plain)

                                            liveActivityButton(for: game)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .top)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(width: sectionWidth, alignment: .leading)
    }

    @ViewBuilder
    private var gamesFailureBanner: some View {
        if case let .failed(message) = viewModel.state, viewModel.games.isEmpty, viewModel.standings.isEmpty == false {
            KboEmptyStateView(
                title: "경기 데이터 연결이 불안정합니다.",
                message: message,
                systemImage: "wifi.exclamationmark",
                style: .card
            )
        }
    }

    private func standingsSection(availableWidth: CGFloat) -> some View {
        let sectionWidth = min(Layout.standingsTableWidth, availableWidth)

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "팀 순위", subtitle: "공식 KBO 시즌 순위와 최근 흐름입니다.")

            switch viewModel.standingsState {
            case .idle where viewModel.standings.isEmpty,
                 .loading where viewModel.standings.isEmpty:
                standingsLoadingView
            case .failed(let message) where viewModel.standings.isEmpty:
                standingsFailureView(message: message)
            default:
                KboGlassPanel(style: .card, cornerRadius: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 0) {
                            TeamStandingHeaderRowView()

                            Divider()
                                .overlay(KboTheme.mutedBorder.opacity(0.75))

                            ForEach(Array(viewModel.standings.prefix(10).enumerated()), id: \.element.id) { index, standing in
                                TeamStandingRowView(
                                    standing: standing,
                                    isFavorite: standing.team.id == viewModel.selectedTeamID
                                )

                                if index < min(viewModel.standings.count, 10) - 1 {
                                    Divider()
                                        .overlay(KboTheme.mutedBorder.opacity(0.6))
                                }
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
                .frame(width: sectionWidth, alignment: .leading)
            }
        }
        .frame(width: sectionWidth, alignment: .leading)
    }

    @ViewBuilder
    private func liveActivityButton(for game: Game) -> some View {
        if let liveActivityState,
           let onToggleLiveActivity,
           liveActivityState(game) != .unavailable {
            let state = liveActivityState(game)

            KboPrimaryActionButton(
                title: state == .stop ? "Live Activity 종료" : "Live Activity 시작",
                systemImage: state == .stop ? "stop.circle" : "bolt.badge.clock",
                tint: state == .stop ? KboSemanticColorToken.warning : KboSemanticColorToken.statusLive
            ) {
                onToggleLiveActivity(game)
            }
        }
    }

    private var commandBarSubtitle: String {
        Self.commandBarSubtitle(
            activeDateString: viewModel.activeDateString,
            lastUpdatedAt: viewModel.lastUpdatedAt
        )
    }

    static func commandBarSubtitle(activeDateString: String, lastUpdatedAt: Date?) -> String {
        let dateText = KboDisplayDateFormatter.fullDate(activeDateString)

        guard let lastUpdatedAt else {
            return dateText
        }

        return "\(dateText) · \(roundedLastUpdatedText(for: lastUpdatedAt))"
    }

    static func roundedLastUpdatedText(for date: Date) -> String {
        lastUpdatedFormatter.string(from: date.flooredToFiveMinuteBoundary(calendar: fiveMinuteCalendar))
    }

    private func contentWidth(for containerWidth: CGFloat) -> CGFloat {
        max(0, containerWidth - Layout.contentHorizontalPadding * 2)
    }

    private func sectionWidth(for availableWidth: CGFloat) -> CGFloat {
        min(Layout.leagueSectionWidth, availableWidth)
    }

    private func standingsBlockWidth(for availableWidth: CGFloat) -> CGFloat {
        min(Layout.commandBarWidth, availableWidth)
    }

    private func commandIcon(systemImage: String, title: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(KboTypographyToken.system(size: 14, weight: .bold, scaledBy: fontScale))

            Text(title)
                .font(KboTypographyToken.caption(scaledBy: fontScale))
        }
        .foregroundStyle(KboTheme.primaryText)
        .frame(width: 58, height: 48)
        .background(KboSurfaceToken.glassControl)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(KboSurfaceToken.glassBorder.opacity(0.72), lineWidth: 1)
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(KboTypographyToken.headline(scaledBy: fontScale))
                .foregroundStyle(KboTheme.primaryText)

            Text(subtitle)
                .font(KboTypographyToken.footnote(scaledBy: fontScale))
                .foregroundStyle(KboTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var favoriteSectionHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text("나의 팀")
                    .font(KboTypographyToken.headline(scaledBy: fontScale))
                    .foregroundStyle(KboTheme.primaryText)

                if let selectedTeam = viewModel.selectedTeam {
                    TeamBadgeView(
                        shortName: selectedTeam.name,
                        fullName: selectedTeam.id,
                        accentColor: TeamColorResolver.color(forTeamID: selectedTeam.id),
                        emphasis: .highlighted,
                        fixedWidth: 128,
                        logoSize: 22,
                        nameWidth: 54
                    )
                }

                Spacer(minLength: 0)
            }

            if viewModel.selectedTeam == nil {
                Text("응원팀을 고르면 오늘 화면과 메뉴바에서 먼저 보여줍니다.")
                    .font(KboTypographyToken.footnote(scaledBy: fontScale))
                    .foregroundStyle(KboTheme.secondaryText)
                    .lineLimit(2)
            } else if viewModel.favoriteGame == nil {
                Text("오늘은 응원팀 경기가 없습니다. 리그 전체 경기로 이어서 확인하세요.")
                    .font(KboTypographyToken.footnote(scaledBy: fontScale))
                    .foregroundStyle(KboTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterPicker: some View {
        Picker("필터", selection: Binding(
            get: { viewModel.filter },
            set: { viewModel.setFilter($0) }
        )) {
            Text("전체").tag(GameListFilter.all)
            Text("진행 중").tag(GameListFilter.live)
            Text("예정").tag(GameListFilter.scheduled)
            Text("종료").tag(GameListFilter.final)
        }
        .pickerStyle(.segmented)
    }

    private var leagueGridColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: Layout.leagueCardMinimumWidth, maximum: 248),
                spacing: Layout.leagueGridSpacing,
                alignment: .top
            )
        ]
    }

    private var selectedTeamRecord: TeamRecordSummary? {
        guard let selectedTeamID = viewModel.selectedTeamID else { return nil }

        for game in viewModel.games {
            if game.awayTeam.id == selectedTeamID {
                return game.teamRecords?.away
            }

            if game.homeTeam.id == selectedTeamID {
                return game.teamRecords?.home
            }
        }

        return nil
    }

    private var groupedLeagueGames: [GameDateSection] {
        if viewModel.games.isEmpty {
            return [
                GameDateSection(
                    date: viewModel.activeDateString,
                    games: []
                )
            ]
        }

        let grouped = Dictionary(grouping: viewModel.leagueGames, by: \.date)
        return grouped.keys.sorted().map { date in
            GameDateSection(
                date: date,
                games: TodayGames(date: date, games: grouped[date] ?? []).orderedGames(
                    filter: .all,
                    preferredTeamID: viewModel.selectedTeamID
                )
            )
        }
    }

    private func dateSectionHeader(_ section: GameDateSection) -> some View {
        HStack(spacing: 10) {
            Text(section.formattedDate)
                .font(KboTypographyToken.headline(scaledBy: fontScale))
                .foregroundStyle(KboTheme.primaryText)

            Text("\(section.games.count)경기")
                .font(KboTypographyToken.caption(scaledBy: fontScale))
                .foregroundStyle(KboTheme.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(KboTheme.cardBackground.opacity(0.65))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(KboColorToken.statusScheduled)

            Text("오늘 경기 데이터를 불러오는 중입니다.")
                .font(KboTypographyToken.body(scaledBy: fontScale))
                .foregroundStyle(KboTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func failureView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(KboTypographyToken.system(size: 34, weight: .semibold, scaledBy: fontScale))
                .foregroundStyle(KboColorToken.warning)

            Text(message)
                .font(KboTypographyToken.body(scaledBy: fontScale))
                .foregroundStyle(KboTheme.primaryText)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var emptyFavoriteView: some View {
        KboEmptyStateView(
            title: viewModel.selectedTeam == nil ? "응원팀을 선택해 주세요." : "오늘은 응원팀 경기가 없습니다.",
            message: viewModel.selectedTeam == nil
                ? "응원팀을 고르면 오늘 화면과 메뉴바에서 먼저 보여줍니다."
                : "리그 전체 경기 목록으로 이어서 확인하세요.",
            systemImage: viewModel.selectedTeam == nil ? "person.crop.circle.badge.plus" : "calendar.badge.clock",
            style: .elevated
        )
    }

    private var emptyView: some View {
        KboEmptyStateView(
            title: "표시할 경기가 없습니다.",
            message: "선택한 상태에 맞는 경기가 아직 없거나 필터를 바꿔야 합니다.",
            systemImage: "line.3.horizontal.decrease.circle",
            style: .card
        )
    }

    private var noGamesTodayView: some View {
        KboEmptyStateView(
            title: "오늘은 경기가 없습니다.",
            message: "다른 날짜를 조회하거나 새로고침해 경기 편성 변경을 확인할 수 있습니다.",
            systemImage: "calendar.badge.exclamationmark",
            style: .card
        )
    }

    private var standingsLoadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(KboColorToken.statusScheduled)

            Text("팀 순위를 불러오는 중입니다.")
                .font(KboTypographyToken.footnote(scaledBy: fontScale))
                .foregroundStyle(KboTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(.horizontal, 16)
        .background(KboTheme.cardBackground.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func standingsFailureView(message: String) -> some View {
        KboEmptyStateView(
            title: "팀 순위를 불러오지 못했습니다.",
            message: message,
            systemImage: "list.number",
            style: .card
        )
    }

    private func gamesFailureView(message: String) -> some View {
        KboEmptyStateView(
            title: "경기 데이터를 불러오지 못했습니다.",
            message: message,
            systemImage: "wifi.exclamationmark",
            style: .card
        )
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                KboColorToken.appBackgroundTop,
                KboColorToken.appBackgroundPrimary,
                KboColorToken.appBackgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    fileprivate static let fiveMinuteCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }()

    private static let lastUpdatedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH시 mm분"
        return formatter
    }()

}

private extension Date {
    func flooredToFiveMinuteBoundary(calendar: Calendar) -> Date {
        let minute = calendar.component(.minute, from: self)
        let flooredMinute = minute - minute % 5

        var components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        components.minute = flooredMinute
        components.second = 0
        components.nanosecond = 0

        return calendar.date(from: components) ?? self
    }
}

private struct GameDateSection: Identifiable {
    let date: String
    let games: [Game]

    var id: String { date }

    var formattedDate: String {
        KboDisplayDateFormatter.fullDate(date)
    }
}

enum KboDisplayDateFormatter {
    static func fullDate(_ value: String) -> String {
        guard let date = inputFormatter.date(from: value) else {
            return value
        }

        return outputFormatter.string(from: date)
    }

    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd (E)"
        return formatter
    }()
}

private struct MyTeamSummaryCardView: View {
    let team: KboTeamOption
    let record: TeamRecordSummary?
    let game: Game?

    var body: some View {
        KboGlassPanel(style: .elevated, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 9) {
                KboMetricRow(metrics, layout: .vertical)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.22),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var accentColor: Color {
        TeamColorResolver.color(forTeamID: team.id)
    }

    private var rankText: String {
        record?.rank.map { "\($0)위" } ?? "-"
    }

    private var recordText: String {
        guard let record else { return "정보 준비 중" }
        return "\(record.wins)승 \(record.losses)패 \(record.draws)무"
    }

    private var metrics: [KboMetricValue] {
        var values = [
            KboMetricValue(title: "순위", value: rankText),
            KboMetricValue(title: "시즌", value: recordText)
        ]

        if let streak = record?.streak, streak.isEmpty == false {
            values.append(KboMetricValue(title: "흐름", value: streak, tint: streakTint(for: streak)))
        }

        return values
    }

    private func streakTint(for streak: String) -> Color? {
        if streak.contains("승") {
            return KboColorToken.success
        }

        if streak.contains("패") {
            return Color(red: 1.0, green: 0.36, blue: 0.42)
        }

        return nil
    }
}

private struct TeamStandingHeaderRowView: View {
    var body: some View {
        TeamStandingTableRowLayout(
            rank: "순위",
            teamID: nil,
            team: "팀",
            wins: "승",
            draws: "무",
            losses: "패",
            winRate: "승률",
            gamesBack: "승차",
            battingAverage: "타율",
            recentTen: "최근 10경기",
            streak: "최근 흐름",
            rankColor: KboTheme.secondaryText,
            teamColor: KboTheme.secondaryText,
            valueColor: KboTheme.secondaryText,
            isHeader: true
        )
    }
}

private struct TeamStandingRowView: View {
    let standing: TeamStanding
    let isFavorite: Bool

    var body: some View {
        TeamStandingTableRowLayout(
            rank: rankText,
            teamID: standing.team.id,
            team: standing.team.name,
            wins: "\(standing.wins)",
            draws: "\(standing.draws)",
            losses: "\(standing.losses)",
            winRate: valueText(standing.winRate),
            gamesBack: valueText(standing.gamesBack),
            battingAverage: "-",
            recentTen: valueText(standing.recentTen),
            streak: streakText(standing.streak),
            rankColor: isFavorite ? accentColor : KboTheme.primaryText,
            teamColor: isFavorite ? accentColor : KboTheme.primaryText,
            valueColor: KboTheme.primaryText,
            isHeader: false
        )
        .background(isFavorite ? accentColor.opacity(0.12) : Color.clear)
    }

    private var accentColor: Color {
        TeamColorResolver.color(forTeamID: standing.team.id)
    }

    private var rankText: String {
        standing.rank.map { "\($0)" } ?? "-"
    }

    private func valueText(_ value: String?) -> String {
        guard let value, value.isEmpty == false else {
            return "-"
        }

        return value
    }

    private func streakText(_ value: String?) -> String {
        let text = valueText(value)
        guard text.hasSuffix("승") || text.hasSuffix("패") else {
            return text
        }

        let suffix = text.hasSuffix("승") ? "승" : "패"
        let countText = text.dropLast()
        guard Int(countText) != nil else {
            return text
        }

        return "\(countText)연\(suffix)"
    }
}

private struct TeamStandingTableRowLayout: View {
    let rank: String
    let teamID: String?
    let team: String
    let wins: String
    let draws: String
    let losses: String
    let winRate: String
    let gamesBack: String
    let battingAverage: String
    let recentTen: String
    let streak: String
    let rankColor: Color
    let teamColor: Color
    let valueColor: Color
    let isHeader: Bool
    @Environment(\.kboFontScale) private var fontScale

    var body: some View {
        HStack(spacing: 12) {
            cell(rank, width: 34, alignment: .center, color: rankColor)

            TeamStandingLogoCellView(
                teamID: teamID,
                accentColor: teamColor,
                isHeader: isHeader
            )

            cell(team, width: 96, alignment: .leading, color: teamColor)

            valueCell(wins, width: 44)
            valueCell(draws, width: 44)
            valueCell(losses, width: 44)
            valueCell(winRate, width: 58)
            valueCell(gamesBack, width: 52)
            valueCell(battingAverage, width: 52)
            cell(recentTen, width: 96, alignment: .center, color: isHeader ? KboTheme.secondaryText : valueColor)
            cell(streak, width: 96, alignment: .center, color: isHeader ? KboTheme.secondaryText : valueColor)
        }
        .padding(.vertical, isHeader ? 9 : 10)
    }

    private func valueCell(_ text: String, width: CGFloat) -> some View {
        cell(text, width: width, alignment: .trailing, color: isHeader ? KboTheme.secondaryText : valueColor)
    }

    private func cell(_ text: String, width: CGFloat, alignment: Alignment, color: Color) -> some View {
        Text(text)
            .font(tableFont)
            .foregroundStyle(color)
            .lineLimit(1)
            .frame(width: width, alignment: alignment)
            .monospacedDigit()
    }

    private var tableFont: Font {
        KboTypographyToken.system(size: 12, weight: .semibold, scaledBy: fontScale)
    }
}

private struct TeamStandingLogoCellView: View {
    let teamID: String?
    let accentColor: Color
    let isHeader: Bool
    @Environment(\.kboFontScale) private var fontScale

    var body: some View {
        Group {
            if isHeader {
                Color.clear
            } else if let logoImage {
                logoImage
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .overlay {
                        Text(teamID.map { String($0.prefix(1)) } ?? "")
                            .font(KboTypographyToken.system(size: 12, weight: .semibold, scaledBy: fontScale))
                            .foregroundStyle(accentColor)
                    }
            }
        }
        .frame(width: 26, height: 26)
    }

    private var logoImage: Image? {
        guard let teamID else { return nil }

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

enum ProbablePitcherChipFormatter {
    static func warningText(for status: StarterStatus) -> String? {
        switch status {
        case .missing:
            return "확인 필요"
        case .ready, .notDue:
            return nil
        }
    }

    static func displayText(for pitcher: ProbablePitcher) -> String? {
        guard let name = trimmed(pitcher.name) else {
            return nil
        }

        guard let record = pitcher.record else {
            return name
        }

        var parts: [String] = []

        switch (record.wins, record.losses) {
        case let (.some(wins), .some(losses)):
            parts.append("\(wins)승 \(losses)패")
        case let (.some(wins), .none):
            parts.append("\(wins)승")
        case let (.none, .some(losses)):
            parts.append("\(losses)패")
        default:
            break
        }

        if let era = record.era {
            parts.append("ERA \(format(era))")
        }

        if let whip = record.whip {
            parts.append("WHIP \(format(whip))")
        }

        guard parts.isEmpty == false else {
            return name
        }

        return "\(name) · \(parts.joined(separator: " · "))"
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

private struct FeaturedGameCardView: View {
    let game: Game
    let favoriteTeamID: String?
    @Environment(\.kboFontScale) private var fontScale

    private enum Layout {
        static let badgeWidth: CGFloat = 124
        static let nameWidth: CGFloat = 54
        static let scoreWidth: CGFloat = 64
        static let logoSize: CGFloat = 24
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text("대표 경기")
                    .font(KboTypographyToken.caption(scaledBy: fontScale))
                    .foregroundStyle(cardAccent)
                    .textCase(.uppercase)
                    .tracking(0.7)

                Spacer()

                Text(gameDateTimeText)
                    .font(KboTypographyToken.caption(scaledBy: fontScale))
                    .foregroundStyle(cardSecondaryText)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .foregroundStyle(cardSecondaryText)
            }

            HStack(alignment: .top, spacing: 12) {
                featuredTeamRow(
                    team: game.awayTeam,
                    score: game.score.away,
                    isFavorite: game.awayTeam.id == favoriteTeamID,
                    showsScore: showsScore,
                    playerRole: playerRole(for: game.awayTeam)
                )

                Spacer(minLength: 16)

                centerGameState

                Spacer(minLength: 16)

                featuredTeamRow(
                    team: game.homeTeam,
                    score: game.score.home,
                    isFavorite: game.homeTeam.id == favoriteTeamID,
                    showsScore: showsScore,
                    playerRole: playerRole(for: game.homeTeam)
                )
            }

            gameMetaRow

            stateContextStrip

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(KboSurfaceToken.cardBorder, lineWidth: 1)
        }
    }

    private var gameDateTimeText: String {
        let date = GameDateSection(date: game.date, games: []).formattedDate
        let time = game.startTime.map { Self.cardTimeFormatter.string(from: $0) } ?? "시간 미정"
        return "\(date) · \(time)"
    }

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: cardGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardGradientColors: [Color] {
        switch game.status {
        case .live:
            return [
                Color(red: 0.14, green: 0.31, blue: 0.28).opacity(0.96),
                Color(red: 0.08, green: 0.10, blue: 0.18).opacity(0.98),
                KboColorToken.statusLive.opacity(0.30)
            ]
        case .scheduled:
            return [
                Color(red: 0.08, green: 0.24, blue: 0.35).opacity(0.96),
                Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.98)
            ]
        case .final:
            return [
                Color(red: 0.17, green: 0.20, blue: 0.25).opacity(0.96),
                Color(red: 0.07, green: 0.08, blue: 0.12).opacity(0.98)
            ]
        case .delayed, .cancelled, .unknown:
            return [
                Color(red: 0.28, green: 0.21, blue: 0.10).opacity(0.92),
                Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.98)
            ]
        }
    }

    private var cardAccent: Color {
        switch game.status {
        case .live:
            return KboColorToken.statusLive
        case .scheduled:
            return KboColorToken.statusScheduled
        case .final:
            return KboColorToken.statusFinal
        case .delayed:
            return KboColorToken.statusDelayed
        case .cancelled, .unknown:
            return KboTheme.secondaryText
        }
    }

    private var cardPrimaryText: Color {
        Color.white.opacity(0.95)
    }

    private var cardSecondaryText: Color {
        Color.white.opacity(0.68)
    }

    private var cardChipText: Color {
        Color(red: 0.06, green: 0.10, blue: 0.14)
    }

    private var statusPillText: String {
        switch game.status {
        case .scheduled:
            return "예정"
        case .live:
            return "LIVE"
        case .final:
            return "FINAL"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return "확인 중"
        }
    }

    private static let cardTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private func featuredTeamRow(team: Team, score: Int, isFavorite: Bool, showsScore: Bool, playerRole: FeaturedCurrentPlayerRole?) -> some View {
        VStack(spacing: 8) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: isFavorite ? .highlighted : .normal,
                fixedWidth: Layout.badgeWidth,
                logoSize: Layout.logoSize,
                nameWidth: Layout.nameWidth,
                foregroundColor: cardPrimaryText
            )

            if showsScore {
                Text("\(score)")
                    .font(KboTypographyToken.system(size: 34, weight: .black, scaledBy: fontScale))
                    .monospacedDigit()
                    .foregroundStyle(cardPrimaryText)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: Layout.scoreWidth, alignment: .center)
            }

            if let playerRole {
                currentPlayerView(playerRole)
            }
        }
        .frame(width: Layout.badgeWidth, alignment: .center)
    }

    private var centerGameState: some View {
        VStack(spacing: 8) {
            Text(centerLabel)
                .font(KboTypographyToken.system(size: game.status == .live ? 14 : 13, weight: .black, scaledBy: fontScale))
                .foregroundStyle(game.status == .live ? cardSecondaryText : cardAccent)
                .lineLimit(1)

            if game.status == .live, game.count != nil || game.bases != nil || game.inning != nil {
                FeaturedGameStateBlockView(
                    inning: game.inning,
                    count: game.count,
                    bases: game.bases
                )
            }
        }
        .frame(width: 104, alignment: .center)
    }

    private var centerLabel: String {
        switch game.status {
        case .scheduled:
            return "VS"
        case .live:
            return "LIVE"
        case .final:
            return "FINAL"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return "확인 중"
        }
    }

    private var showsScore: Bool {
        game.status == .live || game.status == .final
    }

    @ViewBuilder
    private var gameMetaRow: some View {
        HStack(spacing: 12) {
            if let venue = game.venue {
                Label(venue, systemImage: "mappin.and.ellipse")
            }

            if game.status == .live || game.status == .final, let inningText = GameProjectionFormatter.inningText(for: game) {
                Label(inningText, systemImage: game.status == .live ? "baseball.diamond.bases" : "checkmark.seal")
            }

            if game.broadcastChannels.isEmpty == false {
                Label(game.broadcastChannels.joined(separator: ", "), systemImage: "tv")
            }
        }
        .font(KboTypographyToken.caption(scaledBy: fontScale))
        .foregroundStyle(cardSecondaryText)
        .lineLimit(1)
    }

    @ViewBuilder
    private var stateContextStrip: some View {
        switch game.status {
        case .scheduled:
            scheduledContextStrip
        case .live:
            liveContextStrip
        case .final:
            finalContextStrip
        case .delayed, .cancelled, .unknown:
            statusContextStrip
        }
    }

    private var scheduledContextStrip: some View {
        Group {
            if hasProbablePitcherRecord {
                VStack(alignment: .leading, spacing: 8) {
                    scheduledContextChips
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                contextChipRow {
                    scheduledContextChips
                }
            }
        }
    }

    @ViewBuilder
    private var scheduledContextChips: some View {
        situationChip(title: "예정", value: startTimeText, systemImage: "clock.fill")

        if let starterWarning = ProbablePitcherChipFormatter.warningText(for: game.starterStatus) {
            situationChip(title: "선발", value: starterWarning, systemImage: "exclamationmark.triangle.fill")
        }

        if let awayPitcher = ProbablePitcherChipFormatter.displayText(for: game.probablePitchers.away) {
            situationChip(title: "원정 선발", value: awayPitcher, systemImage: "baseball.fill", allowMultilineValue: true)
        }

        if let homePitcher = ProbablePitcherChipFormatter.displayText(for: game.probablePitchers.home) {
            situationChip(title: "홈 선발", value: homePitcher, systemImage: "baseball.fill", allowMultilineValue: true)
        }
    }

    private var hasProbablePitcherRecord: Bool {
        game.probablePitchers.away.record != nil || game.probablePitchers.home.record != nil
    }

    private var liveContextStrip: some View {
        contextChipRow {
            if let recentPlay = GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 42) {
                situationChip(title: "최근", value: recentPlay, systemImage: "quote.bubble.fill")
            }

            if let batter = game.current?.batter?.trimmingCharacters(in: .whitespacesAndNewlines), batter.isEmpty == false {
                situationChip(title: "타자", value: batter, systemImage: "figure.baseball")
            }

            if let pitcher = game.current?.pitcher?.trimmingCharacters(in: .whitespacesAndNewlines), pitcher.isEmpty == false {
                situationChip(title: "투수", value: pitcher, systemImage: "baseball.fill")
            }
        }
    }

    private var finalContextStrip: some View {
        contextChipRow {
            if let boxScore = game.boxScore {
                situationChip(title: "안타", value: "\(boxScore.away.hits ?? 0):\(boxScore.home.hits ?? 0)", systemImage: "baseball")
                situationChip(title: "실책", value: "\(boxScore.away.errors ?? 0):\(boxScore.home.errors ?? 0)", systemImage: "exclamationmark.triangle.fill")
            }

            if let win = game.pitcherDecisions?.win?.trimmingCharacters(in: .whitespacesAndNewlines), win.isEmpty == false {
                situationChip(title: "승", value: win, systemImage: "checkmark.seal.fill")
            }

            if let loss = game.pitcherDecisions?.loss?.trimmingCharacters(in: .whitespacesAndNewlines), loss.isEmpty == false {
                situationChip(title: "패", value: loss, systemImage: "xmark.seal.fill")
            }

            if game.boxScore == nil && game.pitcherDecisions == nil {
                situationChip(title: "종료", value: GameProjectionFormatter.scoreLine(for: game), systemImage: "checkmark.seal")
            }
        }
    }

    private var statusContextStrip: some View {
        contextChipRow {
            situationChip(title: "상태", value: statusPillText, systemImage: "exclamationmark.circle.fill")
            situationChip(title: "예정", value: startTimeText, systemImage: "clock.fill")
        }
    }

    private func contextChipRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                content()
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var startTimeText: String {
        game.startTime.map { Self.cardTimeFormatter.string(from: $0) } ?? "시간 미정"
    }

    private func situationChip(title: String, value: String, systemImage: String, allowMultilineValue: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(KboTypographyToken.system(size: 10, weight: .bold, scaledBy: fontScale))
                .foregroundStyle(cardAccent)

            Text(title)
                .font(KboTypographyToken.system(size: 10, weight: .black, scaledBy: fontScale))
                .foregroundStyle(cardChipText.opacity(0.62))

            Text(value)
                .font(KboTypographyToken.system(size: 12, weight: .semibold, scaledBy: fontScale))
                .foregroundStyle(cardChipText)
                .lineLimit(allowMultilineValue ? 2 : 1)
                .fixedSize(horizontal: false, vertical: allowMultilineValue)
                .minimumScaleFactor(allowMultilineValue ? 1.0 : 0.72)
        }
        .frame(maxWidth: allowMultilineValue ? .infinity : nil, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.66))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        }
    }

    private func playerRole(for team: Team) -> FeaturedCurrentPlayerRole? {
        guard game.status == .live else { return nil }
        let batter = game.current?.batter?.trimmingCharacters(in: .whitespacesAndNewlines)
        let pitcher = game.current?.pitcher?.trimmingCharacters(in: .whitespacesAndNewlines)
        let activeBatter = batter?.isEmpty == false ? batter : nil
        let activePitcher = pitcher?.isEmpty == false ? pitcher : nil

        guard let half = game.inning?.half else {
            return nil
        }

        if team.id == battingTeamID(for: half), let activeBatter {
            return FeaturedCurrentPlayerRole(kind: .batter, name: activeBatter)
        }

        if team.id == pitchingTeamID(for: half), let activePitcher {
            return FeaturedCurrentPlayerRole(kind: .pitcher, name: activePitcher)
        }

        return nil
    }

    private func battingTeamID(for half: InningHalf) -> String {
        half == .top ? game.awayTeam.id : game.homeTeam.id
    }

    private func pitchingTeamID(for half: InningHalf) -> String {
        half == .top ? game.homeTeam.id : game.awayTeam.id
    }

    private func currentPlayerView(_ playerRole: FeaturedCurrentPlayerRole) -> some View {
        HStack(spacing: 6) {
            if let battingOrder = playerRole.battingOrder {
                Text(String(battingOrder))
                    .font(KboTypographyToken.system(size: 11, weight: .black, scaledBy: fontScale))
                    .foregroundStyle(.white)
                    .frame(width: 19, height: 19)
                    .background(KboColorToken.statusScheduled.opacity(0.9))
                    .clipShape(Circle())
            }

            if let positionText = playerRole.positionText {
                Text(positionText)
                    .font(KboTypographyToken.system(size: 12, weight: .bold, scaledBy: fontScale))
                    .foregroundStyle(cardSecondaryText)
                    .lineLimit(1)
            }

            Text(playerRole.name)
                .font(KboTypographyToken.system(size: 13, weight: .semibold, scaledBy: fontScale))
                .foregroundStyle(cardPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(maxWidth: Layout.badgeWidth, minHeight: 32)
        .background(Color.white.opacity(0.16))
        .clipShape(Capsule())
    }
}

private struct FeaturedCurrentPlayerRole {
    enum Kind {
        case batter
        case pitcher
    }

    let kind: Kind
    let name: String
    let battingOrder: Int? = nil
    let position: String? = nil

    var positionText: String? {
        switch kind {
        case .batter:
            return position
        case .pitcher:
            return "P"
        }
    }
}

private struct FeaturedGameStateBlockView: View {
    let inning: InningState?
    let count: CountState?
    let bases: BasesState?

    var body: some View {
        VStack(spacing: 8) {
            if let inning {
                inningIndicator(inning)
            }

            if let count {
                VStack(alignment: .leading, spacing: 5) {
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
                .frame(width: 42, height: 32)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .frame(width: 104)
        .background(KboSurfaceToken.glassControl)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(KboSurfaceToken.cardBorder, lineWidth: 1)
        }
        .fixedSize(horizontal: true, vertical: true)
    }

    private func inningIndicator(_ inning: InningState) -> some View {
        HStack(spacing: 4) {
            Text(String(inning.number))
                .monospacedDigit()

            Text(inning.half == .top ? "▲" : "▼")
                .font(.system(size: 8, weight: .black))
                .baselineOffset(0.5)
        }
        .font(.system(size: 12, weight: .black))
        .foregroundStyle(KboColorToken.statusScheduled)
        .lineLimit(1)
    }

    private func countRow(label: String, value: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(KboTheme.secondaryText)
                .frame(width: 8, alignment: .leading)

            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < clamped(value, total: total) ? color : color.opacity(0.18))
                    .frame(width: 7, height: 7)
                    .overlay {
                        Circle()
                            .stroke(color.opacity(0.45), lineWidth: 0.8)
                    }
            }
        }
    }

    private func clamped(_ value: Int, total: Int) -> Int {
        min(max(value, 0), total)
    }
}

private struct TodayGameCardView: View {
    let game: Game
    let favoriteTeamID: String?
    @Environment(\.kboFontScale) private var fontScale

    private enum Layout {
        static let badgeWidth: CGFloat = 100
        static let nameWidth: CGFloat = 44
        static let scoreWidth: CGFloat = 46
        static let logoSize: CGFloat = 20
        static let metaIconWidth: CGFloat = 18
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                statusRow

                if let inningText = rightStatusText {
                    InningStateView(text: inningText)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                teamRow(team: game.awayTeam, score: game.score.away)
                teamRow(team: game.homeTeam, score: game.score.home)
            }

            metaRow

            if game.status == .live {
                liveContext
            }

            if let recentPlay = game.recentPlay, recentPlay.isEmpty == false {
                Text(recentPlay)
                    .font(KboTypographyToken.footnote(scaledBy: fontScale))
                    .foregroundStyle(KboTheme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(KboTheme.cardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
        .shadow(color: KboColorToken.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
    }

    private var borderColor: Color {
        if game.involves(teamID: favoriteTeamID ?? "") {
            return TeamColorResolver.color(forTeamID: favoriteTeamID ?? "").opacity(0.6)
        }

        return KboTheme.mutedBorder
    }

    private var statusRow: some View {
        LiveBadgeView(text: statusBadgeText, style: badgeStyle)
    }

    @ViewBuilder
    private var metaRow: some View {
        if metaItems.isEmpty == false {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(metaItems.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: item.systemImage)
                            .frame(width: Layout.metaIconWidth, alignment: .center)

                        Text(item.text)
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                }
            }
            .font(KboTypographyToken.caption(scaledBy: fontScale))
            .foregroundStyle(KboTheme.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(KboTheme.elevatedBackground.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(KboTheme.mutedBorder.opacity(0.55), lineWidth: 1)
            }
        }
    }

    private var metaItems: [(systemImage: String, text: String)] {
        var items: [(systemImage: String, text: String)] = []

        if let startTime = game.startTime {
            items.append(("clock", startTime.formatted(.dateTime.hour().minute())))
        }

        if let venue = game.venue, venue.isEmpty == false {
            items.append(("mappin.and.ellipse", venue))
        }

        if game.broadcastChannels.isEmpty == false {
            items.append(("tv", game.broadcastChannels.joined(separator: ", ")))
        }

        return items
    }

    private func teamRow(team: Team, score: Int) -> some View {
        HStack(spacing: 8) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: team.id == favoriteTeamID ? .highlighted : .normal,
                fixedWidth: Layout.badgeWidth,
                logoSize: Layout.logoSize,
                nameWidth: Layout.nameWidth
            )

            ScoreDigitsView(score: score, mode: .scoreboardCompact)
                .frame(minWidth: Layout.scoreWidth, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var liveContext: some View {
        HStack(alignment: .center, spacing: 8) {
            if let count = game.count {
                PitchCountView(balls: count.balls, strikes: count.strikes)
                OutCountView(outs: min(count.outs, 3))
            }

            Spacer(minLength: 0)

            if let bases = game.bases {
                BaseDiamondView(
                    firstOccupied: bases.first,
                    secondOccupied: bases.second,
                    thirdOccupied: bases.third
                )
                .frame(width: 34, height: 34)
            }
        }
    }

    private var rightStatusText: String? {
        guard game.status == .live else { return nil }
        return GameProjectionFormatter.inningText(for: game)
    }

    private var statusBadgeText: String {
        switch game.status {
        case .live:
            return "LIVE"
        case .scheduled:
            return "예정"
        case .final:
            return "종료"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return "확인 필요"
        }
    }

    private var badgeStyle: LiveBadgeView.Style {
        switch game.status {
        case .live:
            return .live
        case .scheduled:
            return .scheduled
        case .final:
            return .final
        case .delayed, .cancelled, .unknown:
            return .delayed
        }
    }

}
