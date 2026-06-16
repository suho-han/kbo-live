import SwiftUI
#if canImport(KboLiveCore)
import KboLiveCore
#endif
#if canImport(KboLiveDesignSystem)
import KboLiveDesignSystem
#endif

public enum LiveActivityControlState: Equatable {
    case unavailable
    case start
    case stop
}

public struct TodayGamesView: View {
    @ObservedObject private var viewModel: TodayGamesViewModel
    @State private var selectedGame: Game?
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
                .navigationTitle("크보 라이브")
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
            case .failed(let message) where viewModel.games.isEmpty:
                failureView(message: message)
            default:
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        commandBar
                        favoriteSection
                        leagueSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
    }

    private var commandBar: some View {
        KboCommandBar(
            title: "KBO LIVE",
            subtitle: commandBarSubtitle
        ) {
            Image(systemName: "baseball.fill")
                .font(.system(size: 21, weight: .bold))
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
    }

    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            favoriteSectionHeader

            if let selectedTeam = viewModel.selectedTeam {
                MyTeamSummaryCardView(
                    team: selectedTeam,
                    record: selectedTeamRecord,
                    game: viewModel.favoriteGame
                )
            }

            if let game = viewModel.favoriteGame {
                VStack(spacing: 10) {
                    Button {
                        selectedGame = game
                    } label: {
                        FeaturedGameCardView(
                            game: game,
                            favoriteTeamID: viewModel.selectedTeamID
                        )
                    }
                    .buttonStyle(.plain)

                    liveActivityButton(for: game)
                }
            } else {
                emptyFavoriteView
            }
        }
    }

    private var leagueSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "리그 전체", subtitle: "진행 중 경기를 우선 정렬한 전체 경기 목록입니다.")
            filterPicker

            if viewModel.leagueGames.isEmpty, viewModel.games.isEmpty == false {
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
                                                if game.status == .scheduled {
                                                    ScheduledGameRowView(
                                                        game: game,
                                                        favoriteTeamID: viewModel.selectedTeamID
                                                    )
                                                } else {
                                                    TodayGameCardView(
                                                        game: game,
                                                        favoriteTeamID: viewModel.selectedTeamID
                                                    )
                                                }
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
        let gameCount = viewModel.games.count
        let dateText = GameDateSection(date: viewModel.activeDateString, games: []).formattedDate
        let teamFocusText = viewModel.selectedTeam.map { "\($0.name) 중심으로 보기 · " } ?? ""

        if gameCount == 0 {
            return "\(teamFocusText)\(dateText) · 편성된 경기가 없습니다."
        }

        return "\(teamFocusText)\(dateText) · \(gameCount)경기 · 진행 중 경기를 먼저 보여줍니다."
    }

    private func commandIcon(systemImage: String, title: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))

            Text(title)
                .font(KboTypographyToken.caption)
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
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            Text(subtitle)
                .font(KboTypographyToken.footnote)
                .foregroundStyle(KboTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var favoriteSectionHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("나의 팀")
                    .font(KboTypographyToken.headline)
                    .foregroundStyle(KboTheme.primaryText)

                Spacer(minLength: 12)

                if let selectedTeam = viewModel.selectedTeam {
                    Text(selectedTeam.koreanFullName)
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(TeamColorResolver.color(forTeamID: selectedTeam.id))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
            }

            if viewModel.selectedTeam == nil {
                Text("응원 팀을 선택하면 가장 관련 있는 경기를 먼저 보여줍니다.")
                    .font(KboTypographyToken.footnote)
                    .foregroundStyle(KboTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterPicker: some View {
        Picker("필터", selection: $viewModel.filter) {
            Text("전체").tag(GameListFilter.all)
            Text("진행 중").tag(GameListFilter.live)
            Text("예정").tag(GameListFilter.scheduled)
            Text("종료").tag(GameListFilter.final)
        }
        .pickerStyle(.segmented)
    }

    private var leagueGridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 184, maximum: 248), spacing: 12, alignment: .top)
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
                games: TodayGames(date: date, games: grouped[date] ?? []).orderedGames(filter: .all)
            )
        }
    }

    private func dateSectionHeader(_ section: GameDateSection) -> some View {
        HStack(spacing: 10) {
            Text(section.formattedDate)
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            Text("\(section.games.count)경기")
                .font(KboTypographyToken.caption)
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
                .font(KboTypographyToken.body)
                .foregroundStyle(KboTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func failureView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(KboColorToken.warning)

            Text(message)
                .font(KboTypographyToken.body)
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
            title: viewModel.selectedTeam == nil ? "응원 팀을 선택해 주세요." : "선택한 팀의 오늘 경기가 없습니다.",
            message: "팀 선택은 상단 메뉴에서 언제든 바꿀 수 있습니다.",
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

}

private struct GameDateSection: Identifiable {
    let date: String
    let games: [Game]

    var id: String { date }

    var formattedDate: String {
        guard date.count == 8 else { return date }

        let year = date.prefix(4)
        let month = date.dropFirst(4).prefix(2)
        let day = date.suffix(2)
        return "\(year).\(month).\(day)"
    }
}

private struct MyTeamSummaryCardView: View {
    let team: KboTeamOption
    let record: TeamRecordSummary?
    let game: Game?

    var body: some View {
        KboGlassPanel(style: .elevated, cornerRadius: 24) {
            HStack(alignment: .center, spacing: 14) {
                TeamBadgeView(
                    shortName: team.name,
                    fullName: team.id,
                    accentColor: accentColor,
                    emphasis: .highlighted,
                    fixedWidth: 118,
                    logoSize: 22,
                    nameWidth: 48
                )

                VStack(alignment: .leading, spacing: 9) {
                    KboMetricRow(metrics)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
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
            KboMetricValue(title: "순위", value: rankText, tint: accentColor),
            KboMetricValue(title: "시즌", value: recordText)
        ]

        if let streak = record?.streak, streak.isEmpty == false {
            values.append(KboMetricValue(title: "흐름", value: streak, tint: accentColor))
        }

        return values
    }
}

private struct FeaturedGameCardView: View {
    let game: Game
    let favoriteTeamID: String?

    private enum Layout {
        static let badgeWidth: CGFloat = 132
        static let nameWidth: CGFloat = 54
        static let scoreWidth: CGFloat = 64
        static let logoSize: CGFloat = 24
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("대표 경기")
                    .font(KboTypographyToken.caption)
                    .foregroundStyle(KboColorToken.statusLive)

                Spacer()

                Text(gameDateTimeText)
                    .font(KboTypographyToken.caption)
                    .foregroundStyle(KboTheme.secondaryText)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .foregroundStyle(KboTheme.secondaryText)
            }

            HStack(spacing: 14) {
                featuredTeamRow(
                    team: game.awayTeam,
                    score: game.score.away,
                    isFavorite: game.awayTeam.id == favoriteTeamID,
                    showsScore: game.status != .scheduled
                )
                Spacer()
                Text("VS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(KboTheme.secondaryText)
                Spacer()
                featuredTeamRow(
                    team: game.homeTeam,
                    score: game.score.home,
                    isFavorite: game.homeTeam.id == favoriteTeamID,
                    showsScore: game.status != .scheduled
                )
            }

            if let venue = game.venue {
                Label(venue, systemImage: "mappin.and.ellipse")
                    .font(KboTypographyToken.caption)
                    .foregroundStyle(KboTheme.secondaryText)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.63, green: 0.15, blue: 0.18).opacity(0.75),
                    Color(red: 0.09, green: 0.10, blue: 0.22).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var gameDateTimeText: String {
        let date = GameDateSection(date: game.date, games: []).formattedDate
        let time = game.startTime.map { Self.cardTimeFormatter.string(from: $0) } ?? "시간 미정"
        return "\(date) · \(time)"
    }

    private static let cardTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private func featuredTeamRow(team: Team, score: Int, isFavorite: Bool, showsScore: Bool) -> some View {
        VStack(spacing: 10) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: isFavorite ? .highlighted : .normal,
                fixedWidth: Layout.badgeWidth,
                logoSize: Layout.logoSize,
                nameWidth: Layout.nameWidth
            )

            if showsScore {
                Text("\(score)")
                    .font(.system(size: 34, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(KboTheme.primaryText)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: Layout.scoreWidth, alignment: .center)
            }
        }
        .frame(width: Layout.badgeWidth, alignment: .center)
    }
}

private struct ScheduledGameRowView: View {
    let game: Game
    let favoriteTeamID: String?

    var body: some View {
        HStack(spacing: 10) {
            teamText(game.awayTeam)

            Text("vs")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(KboTheme.secondaryText)

            teamText(game.homeTeam)

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 3) {
                if let startTime = game.startTime {
                    Text(startTime.formatted(.dateTime.hour().minute()))
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.primaryText)
                        .monospacedDigit()
                } else {
                    Text("예정")
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)
                }

                if let venue = game.venue, venue.isEmpty == false {
                    Text(venue)
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(KboTheme.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(KboTheme.cardBackground.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
    }

    private func teamText(_ team: Team) -> some View {
        Text(team.name)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(team.id == favoriteTeamID ? TeamColorResolver.color(forTeamID: team.id) : KboTheme.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }

    private var borderColor: Color {
        if game.involves(teamID: favoriteTeamID ?? "") {
            return TeamColorResolver.color(forTeamID: favoriteTeamID ?? "").opacity(0.55)
        }

        return KboTheme.mutedBorder.opacity(0.8)
    }
}

private struct TodayGameCardView: View {
    let game: Game
    let favoriteTeamID: String?

    private enum Layout {
        static let badgeWidth: CGFloat = 100
        static let nameWidth: CGFloat = 44
        static let scoreWidth: CGFloat = 46
        static let logoSize: CGFloat = 20
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
                    .font(KboTypographyToken.footnote)
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
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
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

    private var metaRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let startTime = game.startTime {
                Label(startTime.formatted(.dateTime.hour().minute()), systemImage: "clock")
            }

            if let venue = game.venue, venue.isEmpty == false {
                Label(venue, systemImage: "mappin.and.ellipse")
            }
        }
        .font(KboTypographyToken.caption)
        .foregroundStyle(KboTheme.secondaryText)
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
