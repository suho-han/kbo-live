import KboLiveCore
import Testing
@testable import KboLiveFeatures

struct ProbablePitcherChipFormatterTests {
    @Test func formatsPitcherRecordSummaryWhenPresent() {
        let text = ProbablePitcherChipFormatter.displayText(for: ProbablePitcher(
            name: "올러",
            record: PitcherSeasonSummary(wins: 7, losses: 5, era: 2.58, whip: 0.95)
        ))

        #expect(text == "올러 · 7승 5패 · ERA 2.58 · WHIP 0.95")
    }

    @Test func fallsBackToNameWhenRecordIsAbsentOrEmpty() {
        let noRecord = ProbablePitcherChipFormatter.displayText(for: ProbablePitcher(name: "김건우"))
        let emptyRecord = ProbablePitcherChipFormatter.displayText(for: ProbablePitcher(
            name: "김건우",
            record: PitcherSeasonSummary(wins: nil, losses: nil, era: nil, whip: nil)
        ))

        #expect(noRecord == "김건우")
        #expect(emptyRecord == "김건우")
    }

    @Test func formatsMissingStarterWarningOnlyForMissingStatus() {
        #expect(ProbablePitcherChipFormatter.warningText(for: .missing) == "확인 필요")
        #expect(ProbablePitcherChipFormatter.warningText(for: .notDue) == nil)
        #expect(ProbablePitcherChipFormatter.warningText(for: .ready) == nil)
    }
}
