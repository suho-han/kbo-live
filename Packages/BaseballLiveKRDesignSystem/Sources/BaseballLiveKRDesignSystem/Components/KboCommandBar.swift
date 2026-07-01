import SwiftUI

public struct KboCommandBar<LeadingAccessory: View, Actions: View>: View {
    private let eyebrow: String?
    private let title: String
    private let subtitle: String?
    private let leadingAccessory: LeadingAccessory
    private let actions: Actions
    @Environment(\.kboFontScale) private var fontScale

    public init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leadingAccessory: () -> LeadingAccessory = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.leadingAccessory = leadingAccessory()
        self.actions = actions()
    }

    public var body: some View {
        KboGlassPanel(style: .navigation, cornerRadius: 24) {
            HStack(alignment: .center, spacing: 14) {
                leadingAccessory

                VStack(alignment: .leading, spacing: 4) {
                    if let eyebrow, eyebrow.isEmpty == false {
                        Text(eyebrow)
                            .font(KboTypographyToken.caption(scaledBy: fontScale))
                            .foregroundStyle(KboSemanticColorToken.accentMint)
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }

                    Text(title)
                        .font(KboTypographyToken.system(size: 24, weight: .black, scaledBy: fontScale))
                        .foregroundStyle(KboTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if let subtitle, subtitle.isEmpty == false {
                        Text(subtitle)
                            .font(KboTypographyToken.footnote(scaledBy: fontScale))
                            .foregroundStyle(KboTheme.secondaryText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 10)

                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }
}
