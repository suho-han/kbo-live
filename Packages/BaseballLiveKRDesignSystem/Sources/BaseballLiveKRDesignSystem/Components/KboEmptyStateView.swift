import SwiftUI

public struct KboEmptyStateView: View {
    private let title: String
    private let message: String
    private let systemImage: String
    private let style: KboGlassPanelStyle
    @Environment(\.kboFontScale) private var fontScale

    public init(
        title: String,
        message: String,
        systemImage: String = "baseball.diamond.bases",
        style: KboGlassPanelStyle = .card
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.style = style
    }

    public var body: some View {
        KboGlassPanel(style: style, cornerRadius: 22) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(KboTypographyToken.system(size: 18, weight: .semibold, scaledBy: fontScale))
                    .foregroundStyle(KboSemanticColorToken.accentBlue)
                    .frame(width: 34, height: 34)
                    .background(KboSemanticColorToken.accentBlue.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(KboTypographyToken.headline(scaledBy: fontScale))
                        .foregroundStyle(KboTheme.primaryText)

                    Text(message)
                        .font(KboTypographyToken.body(scaledBy: fontScale))
                        .foregroundStyle(KboTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
    }
}
