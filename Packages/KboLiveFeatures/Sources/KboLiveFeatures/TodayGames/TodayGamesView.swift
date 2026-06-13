import SwiftUI
#if canImport(KboLiveCore)
import KboLiveCore
#endif
#if canImport(KboLiveDesignSystem)
import KboLiveDesignSystem
#endif

public struct TodayGamesView: View {
    @ObservedObject private var viewModel: TodayGamesViewModel
    @State private var selectedGame: Game?

    public init(viewModel: TodayGamesViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .background(backgroundView)
                .navigationTitle("나의 팀")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("새로고침") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
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

    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "나의 팀", subtitle: viewModel.selectedTeam?.name ?? "응원 팀을 선택하면 가장 관련 있는 경기를 먼저 보여줍니다.")

            if let game = viewModel.favoriteGame {
                Button {
                    selectedGame = game
                } label: {
                    FeaturedGameCardView(
                        game: game,
                        favoriteTeamID: viewModel.selectedTeamID
                    )
                }
                .buttonStyle(.plain)
            } else {
                emptyFavoriteView
            }
        }
    }

    private var leagueSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "리그 전체", subtitle: "진행 중 경기를 우선 정렬한 전체 경기 목록입니다.")
            filterPicker

            if viewModel.leagueGames.isEmpty {
                emptyView
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.leagueGames) { game in
                        Button {
                            selectedGame = game
                        } label: {
                            TodayGameCardView(
                                game: game,
                                favoriteTeamID: viewModel.selectedTeamID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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

    private var filterPicker: some View {
        Picker("필터", selection: $viewModel.filter) {
            Text("전체").tag(GameListFilter.all)
            Text("진행 중").tag(GameListFilter.live)
            Text("예정").tag(GameListFilter.scheduled)
            Text("종료").tag(GameListFilter.final)
        }
        .pickerStyle(.segmented)
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
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.selectedTeam == nil ? "응원 팀을 선택해 주세요." : "선택한 팀의 오늘 경기가 없습니다.")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            Text("팀 선택은 상단 메뉴에서 언제든 바꿀 수 있습니다.")
                .font(KboTypographyToken.body)
                .foregroundStyle(KboTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(KboTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(KboTheme.mutedBorder, lineWidth: 1)
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("표시할 경기가 없습니다.")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            Text("선택한 상태에 맞는 경기가 아직 없거나 필터를 바꿔야 합니다.")
                .font(KboTypographyToken.body)
                .foregroundStyle(KboTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(KboTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(KboTheme.mutedBorder, lineWidth: 1)
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.05, blue: 0.09),
                KboColorToken.backgroundPrimary,
                KboColorToken.backgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

}

private struct FeaturedGameCardView: View {
    let game: Game
    let favoriteTeamID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("대표 경기")
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboColorToken.statusLive)

                    Text(GameProjectionFormatter.menuBarSecondaryText(for: game) ?? "경기 진행 상황 확인")
                        .font(KboTypographyToken.headline)
                        .foregroundStyle(KboTheme.primaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(KboTheme.secondaryText)
            }

            HStack(spacing: 14) {
                featuredTeamRow(team: game.awayTeam, score: game.score.away, isFavorite: game.awayTeam.id == favoriteTeamID)
                Spacer()
                Text("VS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(KboTheme.secondaryText)
                Spacer()
                featuredTeamRow(team: game.homeTeam, score: game.score.home, isFavorite: game.homeTeam.id == favoriteTeamID)
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

    private func featuredTeamRow(team: Team, score: Int, isFavorite: Bool) -> some View {
        VStack(spacing: 10) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: isFavorite ? .highlighted : .normal
            )

            Text("\(score)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(KboTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TodayGameCardView: View {
    let game: Game
    let favoriteTeamID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow
                    metaRow
                }

                Spacer(minLength: 12)

                if let inningText = statusText {
                    InningStateView(text: inningText)
                }
            }

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    teamRow(team: game.awayTeam, score: game.score.away)
                    teamRow(team: game.homeTeam, score: game.score.home)
                }

                Spacer(minLength: 16)

                liveContext
            }

            if let recentPlay = game.recentPlay, recentPlay.isEmpty == false {
                Text(recentPlay)
                    .font(KboTypographyToken.footnote)
                    .foregroundStyle(KboTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .background(KboTheme.cardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
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
        HStack(spacing: 10) {
            Label(formattedDate(game.date), systemImage: "calendar")

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
        HStack(spacing: 12) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: team.id == favoriteTeamID ? .highlighted : .normal
            )

            ScoreDigitsView(score: score, mode: .scoreboardCompact)
        }
    }

    @ViewBuilder
    private var liveContext: some View {
        if game.status == .live {
            VStack(alignment: .trailing, spacing: 10) {
                if let count = game.count {
                    PitchCountView(balls: count.balls, strikes: count.strikes)
                    OutCountView(outs: min(count.outs, 3))
                }

                if let bases = game.bases {
                    BaseDiamondView(
                        firstOccupied: bases.first,
                        secondOccupied: bases.second,
                        thirdOccupied: bases.third
                    )
                }
            }
        } else if let startTime = game.startTime {
            Text(startTime, format: .dateTime.hour().minute())
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)
        }
    }

    private var statusText: String? {
        GameProjectionFormatter.inningText(for: game)
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

    private func formattedDate(_ value: String) -> String {
        guard value.count == 8 else { return value }

        let year = value.prefix(4)
        let month = value.dropFirst(4).prefix(2)
        let day = value.suffix(2)
        return "\(year).\(month).\(day)"
    }
}
