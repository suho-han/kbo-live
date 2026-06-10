import SwiftUI

public struct InningStateView: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(KboTypographyToken.footnote)
            .foregroundStyle(KboTheme.secondaryText)
            .padding(.horizontal, KboSpacingToken.small)
            .padding(.vertical, 6)
            .background(KboColorToken.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous))
    }
}
