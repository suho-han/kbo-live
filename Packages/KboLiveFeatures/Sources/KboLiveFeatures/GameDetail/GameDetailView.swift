import SwiftUI
#if canImport(KboLiveCore)
import KboLiveCore
#endif
#if canImport(KboLiveDesignSystem)
import KboLiveDesignSystem
#endif

public struct GameDetailView: View {
    @ObservedObject private var viewModel: GameDetailViewModel

    private enum TeamBadgeLayout {
        static let width: CGFloat = 112
        static let nameWidth: CGFloat = 42
        static let logoSize: CGFloat = 22
    }

    public init(viewModel: GameDetailViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                loadingView
            case .loading where viewModel.game == nil:
                loadingView
            case .failed(let message) where viewModel.game == nil:
                failureView(message: message)
            default:
                contentView
            }
        }
        .background(backgroundView)
        .navigationTitle("경기 상세")
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
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let game = viewModel.game {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topLine(game: game)

                    switch game.status {
                    case .scheduled:
                        scheduledAnalysisView(game: game)
                    case .live:
                        liveBallparkView(game: game)
                    case .final:
                        finalScoreboardView(game: game)
                    case .delayed, .cancelled, .unknown:
                        unavailableView(game: game)
                    }

                    gameInfoGrid(game: game)

                    if game.status == .live,
                       let recentPlay = GameProjectionFormatter.shortRecentPlay(game.recentPlay, limit: 220) {
                        recentPlayCard(recentPlay)
                    }
                }
                .padding(20)
            }
            .refreshable {
                await viewModel.refresh()
            }
        } else {
            failureView(message: "경기 정보를 찾지 못했습니다.")
        }
    }

    private var loadingView: some View {
        ProgressView("경기 상세를 불러오는 중입니다.")
            .tint(KboColorToken.statusScheduled)
    }

    private func topLine(game: Game) -> some View {
        HStack(spacing: 10) {
            statusChip(game: game)

            Text("\(formattedDate(game.date)) \(startTimeText(for: game) ?? "")")
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)

            if let venue = game.venue {
                Text("· \(venue)")
                    .font(KboTypographyToken.caption)
                    .foregroundStyle(KboTheme.secondaryText)
            }

            Spacer()
        }
    }

    private func scheduledAnalysisView(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            detailTitle("프리게임 전력 분석", subtitle: "선발 매치업과 팀 흐름을 먼저 확인합니다.")

            HStack(alignment: .top, spacing: 14) {
                teamPreviewPanel(
                    team: game.awayTeam,
                    pitcher: game.probablePitchers.away.name,
                    record: game.teamRecords?.away,
                    summary: game.analysis?.awaySummary
                )

                VStack(spacing: 10) {
                    Text("VS")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(KboTheme.primaryText)
                    Text(startTimeText(for: game) ?? "예정")
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)
                }
                .frame(width: 72)
                .padding(.top, 30)

                teamPreviewPanel(
                    team: game.homeTeam,
                    pitcher: game.probablePitchers.home.name,
                    record: game.teamRecords?.home,
                    summary: game.analysis?.homeSummary
                )
            }

            if let lineup = game.lineupPreview {
                lineupPreviewCard(game: game, lineup: lineup)
            }

            keyPointCard(points: game.analysis?.keyPoints ?? [])
        }
        .detailCard()
    }

    private func liveBallparkView(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            detailTitle("라이브 경기장", subtitle: statusText(for: game))
            scoreboardView(game: game, isFinal: false)

            HStack(alignment: .top, spacing: 16) {
                fieldView(game: game)
                    .frame(maxWidth: .infinity, minHeight: 300)

                VStack(spacing: 14) {
                    countBoard(game: game)
                    currentMatchupCard(game: game)
                }
                .frame(maxWidth: .infinity)
            }

            keyPointCard(points: game.analysis?.keyPoints ?? [])
        }
        .detailCard()
    }

    private func finalScoreboardView(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            detailTitle("최종 전광판", subtitle: "경기 종료 후 핵심 기록입니다.")
            scoreboardView(game: game, isFinal: true)

            if let boxScore = game.boxScore, !boxScore.linescore.isEmpty {
                linescoreTable(game: game, boxScore: boxScore)
            }

            if let pitcherDecisionText = pitcherDecisionText(for: game) {
                metricPill(title: "승패 투수", value: pitcherDecisionText)
            }

            HStack(spacing: 14) {
                teamResultPanel(
                    team: game.awayTeam,
                    record: game.teamRecords?.away,
                    headToHeadText: headToHeadText(score: game.score.away, opponentScore: game.score.home)
                )
                teamResultPanel(
                    team: game.homeTeam,
                    record: game.teamRecords?.home,
                    headToHeadText: headToHeadText(score: game.score.home, opponentScore: game.score.away)
                )
            }

            keyPointCard(points: game.analysis?.keyPoints ?? [])
        }
        .detailCard()
    }

    private func unavailableView(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            detailTitle("경기 상태", subtitle: statusText(for: game))

            HStack(spacing: 12) {
                metricPill(title: "상태", value: statusText(for: game))
                metricPill(title: "예정 시간", value: startTimeText(for: game) ?? "-")
                metricPill(title: "구장", value: game.venue ?? "-")
            }
        }
        .detailCard()
    }

    private func scoreboardView(game: Game, isFinal: Bool) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(isFinal ? "FINAL" : GameProjectionFormatter.inningText(for: game) ?? "LIVE")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(isFinal ? KboColorToken.statusFinal : KboColorToken.statusLive)
                Spacer()
                Text(game.venue ?? "KBO")
                    .font(KboTypographyToken.caption)
                    .foregroundStyle(KboTheme.secondaryText)
            }

            HStack(alignment: .center, spacing: 16) {
                scoreboardTeam(team: game.awayTeam, score: game.score.away)
                Text(":")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(KboTheme.secondaryText)
                scoreboardTeam(team: game.homeTeam, score: game.score.home)
            }
        }
        .padding(22)
        .background(scoreboardBackground(game: game))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(KboTheme.mutedBorder, lineWidth: 1)
        }
    }

    private func scoreboardTeam(team: Team, score: Int) -> some View {
        VStack(spacing: 12) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: .highlighted,
                fixedWidth: TeamBadgeLayout.width,
                logoSize: TeamBadgeLayout.logoSize,
                nameWidth: TeamBadgeLayout.nameWidth
            )

            Text("\(score)")
                .font(.system(size: 58, weight: .black))
                .monospacedDigit()
                .foregroundStyle(KboTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func fieldView(game: Game) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.22, blue: 0.14),
                            Color(red: 0.10, green: 0.34, blue: 0.21)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Diamond()
                .fill(Color(red: 0.54, green: 0.34, blue: 0.18))
                .frame(width: 180, height: 180)
                .offset(y: 24)
                .overlay {
                    Diamond()
                        .stroke(KboSurfaceToken.glassBorder, lineWidth: 3)
                        .frame(width: 180, height: 180)
                        .offset(y: 24)
                }

            baseMarker(label: "2B", occupied: game.bases?.second == true)
                .offset(y: -70)
            baseMarker(label: "3B", occupied: game.bases?.third == true)
                .offset(x: -88, y: 22)
            baseMarker(label: "1B", occupied: game.bases?.first == true)
                .offset(x: 88, y: 22)
            baseMarker(label: "H", occupied: false)
                .offset(y: 116)

            if let inning = GameProjectionFormatter.inningText(for: game) {
                Text(inning)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(KboTheme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(KboSurfaceToken.criticalOverlay)
                    .clipShape(Capsule())
                    .offset(y: -128)
            }
        }
        .overlay(alignment: .bottomLeading) {
            Text("BASE RUNNERS")
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)
                .padding(18)
        }
    }

    private func countBoard(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("볼카운트")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            if let count = game.count {
                HStack(spacing: 12) {
                    countDots(title: "B", count: count.balls, total: 4, color: KboColorToken.success)
                    countDots(title: "S", count: count.strikes, total: 3, color: KboColorToken.warning)
                    countDots(title: "O", count: count.outs, total: 3, color: KboColorToken.statusLive)
                }
            } else {
                Text("카운트 정보 없음")
                    .font(KboTypographyToken.body)
                    .foregroundStyle(KboTheme.secondaryText)
            }
        }
        .miniCard()
    }

    private func currentMatchupCard(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("현재 승부")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            metricPill(title: "타자", value: game.current?.batter ?? "-")
            metricPill(title: "투수", value: game.current?.pitcher ?? "-")
        }
        .miniCard()
    }

    private func teamPreviewPanel(team: Team, pitcher: String?, record: TeamRecordSummary?, summary: String?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            TeamBadgeView(
                shortName: team.name,
                fullName: team.id,
                accentColor: TeamColorResolver.color(forTeamID: team.id),
                emphasis: .highlighted,
                fixedWidth: TeamBadgeLayout.width,
                logoSize: TeamBadgeLayout.logoSize,
                nameWidth: TeamBadgeLayout.nameWidth
            )

            metricPill(title: "예상 선발", value: pitcher ?? "-")
            metricPill(title: "시즌", value: recordText(record))

            if let summary {
                Text(summary)
                    .font(KboTypographyToken.caption)
                    .foregroundStyle(KboTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .miniCard()
    }

    private func teamResultPanel(team: Team, record: TeamRecordSummary?, headToHeadText: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                TeamBadgeView(
                    shortName: team.name,
                    fullName: team.id,
                    accentColor: TeamColorResolver.color(forTeamID: team.id),
                    emphasis: .highlighted,
                    fixedWidth: TeamBadgeLayout.width,
                    logoSize: TeamBadgeLayout.logoSize,
                    nameWidth: TeamBadgeLayout.nameWidth
                )
                Spacer()
                Text(record?.rank.map { "\($0)위" } ?? "시즌")
                    .font(KboTypographyToken.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(KboTheme.secondaryText)
            }

            Text("\(seasonRecordText(record)) · \(headToHeadText)")
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)
        }
        .miniCard()
    }

    private func lineupPreviewCard(game: Game, lineup: LineupPreview) -> some View {
        HStack(alignment: .top, spacing: 14) {
            lineupColumn(title: "\(game.awayTeam.name) 예상 상위", names: lineup.away)
            lineupColumn(title: "\(game.homeTeam.name) 예상 상위", names: lineup.home)
        }
    }

    private func lineupColumn(title: String, names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)

            ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                Text("\(index + 1). \(name)")
                    .font(KboTypographyToken.body)
                    .foregroundStyle(KboTheme.primaryText)
            }
        }
        .miniCard()
    }

    private func linescoreTable(game: Game, boxScore: BoxScore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이닝별 득점")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .center, spacing: 10) {
                    linescoreRow(label: "팀", values: boxScore.linescore.map { "\($0.inning)" }, trailing: ["R", "H", "E"])
                    linescoreRow(
                        label: game.awayTeam.name,
                        values: boxScore.linescore.map { scoreText($0.away) },
                        trailing: [
                            "\(boxScore.away.runs)",
                            scoreText(boxScore.away.hits),
                            scoreText(boxScore.away.errors)
                        ]
                    )
                    linescoreRow(
                        label: game.homeTeam.name,
                        values: boxScore.linescore.map { scoreText($0.home) },
                        trailing: [
                            "\(boxScore.home.runs)",
                            scoreText(boxScore.home.hits),
                            scoreText(boxScore.home.errors)
                        ]
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .miniCard()
    }

    private func linescoreRow(label: String, values: [String], trailing: [String]) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.primaryText)
                .frame(width: 58, alignment: .center)

            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .font(KboTypographyToken.caption)
                    .monospacedDigit()
                    .foregroundStyle(KboTheme.secondaryText)
                    .frame(width: 26)
            }

            ForEach(Array(trailing.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .font(KboTypographyToken.caption)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(KboTheme.primaryText)
                    .frame(width: 28)
            }
        }
    }

    private func gameInfoGrid(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("경기 정보")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            HStack(spacing: 12) {
                metricPill(title: "경기일", value: formattedDate(game.date))
                metricPill(title: "시간", value: startTimeText(for: game) ?? "-")
                metricPill(title: "구장", value: game.venue ?? "-")
            }

            HStack(spacing: 12) {
                metricPill(title: "상태", value: statusText(for: game))
                metricPill(title: "중계", value: broadcastText(for: game))
                metricPill(title: "경기 ID", value: game.id)
            }
        }
        .detailCard()
    }

    private func keyPointCard(points: [String]) -> some View {
        let displayPoints = points.isEmpty ? ["추가 분석 데이터가 들어오면 여기에 표시됩니다."] : points

        return VStack(alignment: .leading, spacing: 10) {
            Text("체크 포인트")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            ForEach(Array(displayPoints.enumerated()), id: \.offset) { _, point in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(KboColorToken.statusScheduled)
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)
                    Text(point)
                        .font(KboTypographyToken.body)
                        .foregroundStyle(KboTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .miniCard()
    }

    private func detailTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(KboTheme.primaryText)
            Text(subtitle)
                .font(KboTypographyToken.body)
                .foregroundStyle(KboTheme.secondaryText)
        }
    }

    private func statusChip(game: Game) -> some View {
        KboStatusPill(
            text: chipText(for: game),
            style: statusPillStyle(for: game),
            showsPulse: game.status == .live
        )
    }

    private func statusPillStyle(for game: Game) -> KboStatusPill.Style {
        switch game.status {
        case .live:
            return .live
        case .final:
            return .final
        case .delayed:
            return .delayed
        case .scheduled:
            return .scheduled
        case .cancelled, .unknown:
            return .neutral
        }
    }

    private func baseMarker(label: String, occupied: Bool) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(occupied ? Color.black : KboTheme.secondaryText)
            .frame(width: 34, height: 34)
            .background(occupied ? KboColorToken.warning : KboSurfaceToken.glassControl)
            .clipShape(Diamond())
            .overlay {
                Diamond()
                    .stroke(KboSurfaceToken.glassBorder, lineWidth: 1)
            }
    }

    private func countDots(title: String, count: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)

            HStack(spacing: 5) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < count ? color : KboSurfaceToken.glassControl)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)
            Text(value)
                .font(KboTypographyToken.body)
                .foregroundStyle(KboTheme.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KboTheme.cardBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statCell(_ title: String, _ value: Int?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(KboTypographyToken.caption)
                .foregroundStyle(KboTheme.secondaryText)
            Text(scoreText(value))
                .font(KboTypographyToken.body)
                .monospacedDigit()
                .foregroundStyle(KboTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func recentPlayCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 플레이")
                .font(KboTypographyToken.headline)
                .foregroundStyle(KboTheme.primaryText)

            Text(text)
                .font(KboTypographyToken.body)
                .foregroundStyle(KboTheme.secondaryText)
        }
        .detailCard()
    }

    private func failureView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(KboColorToken.warning)
            Text(message)
                .font(KboTypographyToken.body)
                .foregroundStyle(KboTheme.primaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
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

    private func scoreboardBackground(game: Game) -> LinearGradient {
        LinearGradient(
            colors: [
                TeamColorResolver.color(forTeamID: game.awayTeam.id).opacity(0.34),
                Color(red: 0.08, green: 0.10, blue: 0.15),
                TeamColorResolver.color(forTeamID: game.homeTeam.id).opacity(0.34)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func formattedDate(_ value: String) -> String {
        KboDisplayDateFormatter.fullDate(value)
    }

    private func statusText(for game: Game) -> String {
        GameProjectionFormatter.menuBarSecondaryText(for: game)
        ?? GameProjectionFormatter.inningText(for: game)
        ?? game.status.rawValue
    }

    private func chipText(for game: Game) -> String {
        switch game.status {
        case .scheduled:
            return "예정"
        case .live:
            return "진행중"
        case .final:
            return "종료"
        case .delayed:
            return "지연"
        case .cancelled:
            return "취소"
        case .unknown:
            return "확인중"
        }
    }

    private func statusColor(for game: Game) -> Color {
        switch game.status {
        case .scheduled:
            return KboColorToken.statusScheduled
        case .live:
            return KboColorToken.statusLive
        case .final:
            return KboColorToken.statusFinal
        case .delayed:
            return KboColorToken.statusDelayed
        case .cancelled, .unknown:
            return KboTheme.secondaryText
        }
    }

    private func startTimeText(for game: Game) -> String? {
        game.startTime?.formatted(.dateTime.hour().minute())
    }

    private func broadcastText(for game: Game) -> String {
        game.broadcastChannels.isEmpty ? "-" : game.broadcastChannels.joined(separator: ", ")
    }

    private func pitcherDecisionText(for game: Game) -> String? {
        guard let decisions = game.pitcherDecisions else { return nil }
        let parts = [
            decisions.win.map { "승 \($0)" },
            decisions.loss.map { "패 \($0)" },
            decisions.save.map { "세 \($0)" }
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func recordText(_ record: TeamRecordSummary?) -> String {
        guard let record else { return "-" }
        var parts = ["\(record.wins)승 \(record.losses)패 \(record.draws)무"]
        if let rank = record.rank {
            parts.append("\(rank)위")
        }
        if let streak = record.streak {
            parts.append(streak)
        }
        return parts.joined(separator: " · ")
    }

    private func seasonRecordText(_ record: TeamRecordSummary?) -> String {
        guard let record else { return "-" }
        return "\(record.wins)승 \(record.losses)패 \(record.draws)무"
    }

    private func headToHeadText(score: Int, opponentScore: Int) -> String {
        if score > opponentScore {
            return "상대전적 1승 0패"
        }

        if score < opponentScore {
            return "상대전적 0승 1패"
        }

        return "상대전적 0승 0패"
    }

    private func scoreText(_ value: Int?) -> String {
        value.map(String.init) ?? "-"
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private extension View {
    func detailCard() -> some View {
        padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KboTheme.elevatedBackground.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(KboTheme.mutedBorder, lineWidth: 1)
            }
    }

    func miniCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KboTheme.cardBackground.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
