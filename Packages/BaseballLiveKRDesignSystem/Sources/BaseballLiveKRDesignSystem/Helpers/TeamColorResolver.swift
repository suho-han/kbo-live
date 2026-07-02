import SwiftUI

public enum TeamColorResolver {
    public struct LogoTokenStyle: Sendable {
        public let letter: String
        public let fill: Color
        public let stroke: Color
        public let background: Color

        public init(letter: String, fill: Color, stroke: Color, background: Color) {
            self.letter = letter
            self.fill = fill
            self.stroke = stroke
            self.background = background
        }
    }

    public static func color(forTeamID teamID: String) -> Color {
        switch normalize(teamID) {
        case "LG":
            return TeamColorPalette.lgTwinsPrimary
        case "OB", "DOOSAN":
            return TeamColorPalette.doosanBearsPrimary
        case "HT", "KIA":
            return TeamColorPalette.kiaTigersPrimary
        case "LT", "LOTTE":
            return TeamColorPalette.lotteGiantsPrimary
        case "SK", "SSG":
            return TeamColorPalette.ssgLandersPrimary
        case "HH", "HANWHA":
            return TeamColorPalette.hanwhaEaglesPrimary
        case "NC":
            return TeamColorPalette.ncDinosPrimary
        case "KT":
            return TeamColorPalette.ktWizPrimary
        case "SS", "SAMSUNG":
            return TeamColorPalette.samsungLionsPrimary
        case "WO", "KIWOOM":
            return TeamColorPalette.kiwoomHeroesPrimary
        default:
            return TeamColorPalette.fallbackPrimary
        }
    }

    public static func usesLightForeground(forTeamID teamID: String) -> Bool {
        switch normalize(teamID) {
        case "LG",
             "OB", "DOOSAN",
             "HT", "KIA",
             "LT", "LOTTE",
             "SK", "SSG",
             "NC",
             "KT",
             "SS", "SAMSUNG",
             "WO", "KIWOOM":
            return true
        default:
            return false
        }
    }

    public static func logoLetter(forTeamID teamID: String?, fallbackName: String) -> String {
        let normalizedTeamID = teamID.map(normalize) ?? ""

        switch normalizedTeamID {
        case "LG":
            return "L"
        case "OB", "DOOSAN":
            return "D"
        case "HT", "KIA":
            return "K"
        case "LT", "LOTTE":
            return "L"
        case "SK", "SSG":
            return "S"
        case "HH", "HANWHA":
            return "H"
        case "NC":
            return "N"
        case "KT":
            return "K"
        case "SS", "SAMSUNG":
            return "S"
        case "WO", "KIWOOM":
            return "K"
        default:
            let trimmedName = fallbackName.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(trimmedName.prefix(1)).uppercased()
        }
    }

    public static func logoTokenStyle(forTeamID teamID: String?, fallbackName: String) -> LogoTokenStyle {
        let normalizedTeamID = teamID.map(normalize) ?? ""
        let letter = logoLetter(forTeamID: teamID, fallbackName: fallbackName)

        switch normalizedTeamID {
        case "LG":
            return LogoTokenStyle(
                letter: letter,
                fill: TeamColorPalette.lgTwinsPrimary,
                stroke: TeamColorPalette.lgTwinsSecondary,
                background: .white
            )
        case "OB", "DOOSAN":
            return LogoTokenStyle(
                letter: letter,
                fill: TeamColorPalette.doosanBearsPrimary,
                stroke: TeamColorPalette.doosanBearsSecondary,
                background: .white
            )
        case "HT", "KIA":
            return LogoTokenStyle(
                letter: letter,
                fill: TeamColorPalette.kiaTigersPrimary,
                stroke: TeamColorPalette.kiaTigersSecondary,
                background: .white
            )
        case "LT", "LOTTE":
            return LogoTokenStyle(
                letter: letter,
                fill: TeamColorPalette.lotteGiantsPrimary,
                stroke: TeamColorPalette.lotteGiantsSecondary,
                background: .white
            )
        case "SK", "SSG":
            return LogoTokenStyle(letter: letter, fill: TeamColorPalette.ssgLandersPrimary, stroke: .white, background: .white)
        case "HH", "HANWHA":
            return LogoTokenStyle(letter: letter, fill: .black, stroke: TeamColorPalette.hanwhaEaglesPrimary, background: .white)
        case "NC":
            return LogoTokenStyle(
                letter: letter,
                fill: TeamColorPalette.ncDinosPrimary,
                stroke: TeamColorPalette.ncDinosSecondary,
                background: .white
            )
        case "KT":
            return LogoTokenStyle(letter: letter, fill: .black, stroke: .white, background: .white)
        case "SS", "SAMSUNG":
            return LogoTokenStyle(letter: letter, fill: TeamColorPalette.samsungLionsPrimary, stroke: .white, background: .white)
        case "WO", "KIWOOM":
            return LogoTokenStyle(
                letter: letter,
                fill: TeamColorPalette.kiwoomHeroesPrimary,
                stroke: TeamColorPalette.kiwoomHeroesSecondary,
                background: .white
            )
        default:
            return LogoTokenStyle(letter: letter, fill: color(forTeamID: normalizedTeamID), stroke: KboColorToken.textPrimary, background: .white)
        }
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
