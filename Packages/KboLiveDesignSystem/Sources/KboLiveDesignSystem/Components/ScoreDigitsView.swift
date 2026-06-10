import SwiftUI

public struct ScoreDigitsView: View {
    public enum Mode: Sendable {
        case scoreboardLarge
        case scoreboardCompact
        case menuBarCompact
    }

    private let score: Int
    private let mode: Mode

    public init(score: Int, mode: Mode = .scoreboardCompact) {
        self.score = score
        self.mode = mode
    }

    public var body: some View {
        Text(String(score))
            .font(font)
            .monospacedDigit()
            .foregroundStyle(KboTheme.primaryText)
            .frame(minWidth: minWidth, alignment: .trailing)
    }

    private var font: Font {
        switch mode {
        case .scoreboardLarge:
            return KboTypographyToken.scoreLarge
        case .scoreboardCompact:
            return KboTypographyToken.scoreCompact
        case .menuBarCompact:
            return KboTypographyToken.menuBarCompact
        }
    }

    private var minWidth: CGFloat {
        switch mode {
        case .scoreboardLarge:
            return 44
        case .scoreboardCompact:
            return 28
        case .menuBarCompact:
            return 18
        }
    }
}
