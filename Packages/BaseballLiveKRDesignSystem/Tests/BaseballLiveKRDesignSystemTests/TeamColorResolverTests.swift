import Testing
@testable import BaseballLiveKRDesignSystem

struct TeamColorResolverTests {
    @Test func usesLightForegroundForDarkTeamColors() {
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "LG"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "KT"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "OB"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "HT"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "LT"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "SK"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "NC"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "SS"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "WO"))
    }

    @Test func keepsTeamColorForegroundForBrightTeamColors() {
        #expect(!TeamColorResolver.usesLightForeground(forTeamID: "HH"))
        #expect(!TeamColorResolver.usesLightForeground(forTeamID: "HANWHA"))
    }

    @Test func normalizesWhitespaceAndFullTeamIdentifiers() {
        #expect(TeamColorResolver.usesLightForeground(forTeamID: " kt "))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "Doosan"))
        #expect(!TeamColorResolver.usesLightForeground(forTeamID: "hanwha"))
    }
}
