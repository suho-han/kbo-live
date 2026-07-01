import CoreGraphics
import Testing
@testable import BaseballLiveKRFeatures

struct TodayGamesLayoutTests {
    @Test func mainWindowMinimumWidthMatchesLeagueSectionWidth() {
        let expectedLeagueWidth = TodayGamesView.Layout.leagueCardMinimumWidth
            * CGFloat(TodayGamesView.Layout.leagueGridColumnCount)
            + TodayGamesView.Layout.leagueGridSpacing
            * CGFloat(TodayGamesView.Layout.leagueGridColumnCount - 1)

        #expect(TodayGamesView.Layout.leagueSectionWidth == expectedLeagueWidth)
        #expect(
            TodayGamesView.Layout.minimumWindowWidth
                == TodayGamesView.Layout.leagueSectionWidth
                + TodayGamesView.Layout.contentHorizontalPadding * 2
        )
    }

    @Test func commandBarWidthMatchesTeamStandingsWidth() {
        #expect(TodayGamesView.Layout.commandBarWidth == TodayGamesView.Layout.standingsTableWidth)
    }
}
