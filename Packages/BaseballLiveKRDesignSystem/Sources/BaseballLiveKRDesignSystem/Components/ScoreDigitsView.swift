import SwiftUI

public struct ScoreDigitsView: View {
    public enum Mode: Sendable {
        case scoreboardLarge
        case scoreboardCompact
        case menuBarCompact
    }

    private let score: Int
    private let mode: Mode
    @Environment(\.kboFontScale) private var fontScale

    public init(score: Int, mode: Mode = .scoreboardCompact) {
        self.score = score
        self.mode = mode
    }

    public var body: some View {
        Text(String(score))
            .font(font)
            .monospacedDigit()
            .foregroundStyle(KboTheme.primaryText)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: minWidth, alignment: .trailing)
    }

    private var font: Font {
        switch mode {
        case .scoreboardLarge:
            return KboTypographyToken.scoreLarge(scaledBy: fontScale)
        case .scoreboardCompact:
            return KboTypographyToken.scoreCompact(scaledBy: fontScale)
        case .menuBarCompact:
            return KboTypographyToken.menuBarCompact(scaledBy: fontScale)
        }
    }

    private var minWidth: CGFloat {
        switch mode {
        case .scoreboardLarge:
            return 64
        case .scoreboardCompact:
            return 44
        case .menuBarCompact:
            return 24
        }
    }
}
