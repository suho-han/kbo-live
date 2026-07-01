import Foundation
import Testing
@testable import BaseballLiveKRFeatures

struct KboDisplayDateFormatterTests {
    @Test func fullDateIncludesWeekday() {
        #expect(KboDisplayDateFormatter.fullDate("20260618") == "2026.06.18 (목)")
    }

    @Test func fullDateFallsBackForInvalidInput() {
        #expect(KboDisplayDateFormatter.fullDate("2026-06-18") == "2026-06-18")
    }

    @MainActor
    @Test func commandBarSubtitleShowsOnlyDateAndRoundedFiveMinuteTime() throws {
        let date = try #require(DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(identifier: "Asia/Seoul"),
            year: 2026,
            month: 6,
            day: 29,
            hour: 18,
            minute: 12,
            second: 5
        ).date)

        #expect(
            TodayGamesView.commandBarSubtitle(
                activeDateString: "20260629",
                lastUpdatedAt: date
            ) == "2026.06.29 (월) · 18시 10분"
        )
    }

    @MainActor
    @Test func commandBarSubtitleOmitsStatusCopyWhenWaitingForFirstRefresh() {
        #expect(
            TodayGamesView.commandBarSubtitle(
                activeDateString: "20260629",
                lastUpdatedAt: nil
            ) == "2026.06.29 (월)"
        )
    }
}
