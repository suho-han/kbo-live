import SwiftUI

public struct TeamBadgeView: View {
    public enum Emphasis: Sendable {
        case normal
        case highlighted
    }

    private let shortName: String
    private let fullName: String?
    private let accentColor: Color
    private let emphasis: Emphasis

    public init(
        shortName: String,
        fullName: String? = nil,
        accentColor: Color,
        emphasis: Emphasis = .normal
    ) {
        self.shortName = shortName
        self.fullName = fullName
        self.accentColor = accentColor
        self.emphasis = emphasis
    }

    public var body: some View {
        HStack(spacing: KboSpacingToken.small) {
            Circle()
                .fill(accentColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(shortName)
                    .font(KboTypographyToken.headline)
                    .foregroundStyle(KboTheme.primaryText)

                if let fullName, fullName.isEmpty == false {
                    Text(fullName)
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)
                }
            }
        }
        .padding(.horizontal, KboSpacingToken.small)
        .padding(.vertical, 6)
        .background(accentColor.opacity(emphasis == .highlighted ? 0.24 : 0.14))
        .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous)
                .stroke(accentColor.opacity(0.5), lineWidth: emphasis == .highlighted ? 1.5 : 1)
        }
    }
}
