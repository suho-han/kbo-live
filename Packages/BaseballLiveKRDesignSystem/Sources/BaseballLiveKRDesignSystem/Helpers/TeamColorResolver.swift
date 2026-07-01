import SwiftUI

public enum TeamColorResolver {
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

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
