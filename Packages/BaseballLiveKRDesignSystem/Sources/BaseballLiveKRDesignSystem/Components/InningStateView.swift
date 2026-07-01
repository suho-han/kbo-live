import SwiftUI

public struct InningStateView: View {
    private let text: String
    @Environment(\.kboFontScale) private var fontScale

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(KboTypographyToken.footnote(scaledBy: fontScale))
            .foregroundStyle(KboTheme.secondaryText)
            .padding(.horizontal, KboSpacingToken.small)
            .padding(.vertical, 6)
            .background(KboColorToken.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous))
    }
}
