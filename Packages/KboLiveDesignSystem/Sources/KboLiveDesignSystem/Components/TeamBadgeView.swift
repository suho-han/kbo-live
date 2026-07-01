import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct TeamBadgeView: View {
    public enum Emphasis: Sendable {
        case normal
        case highlighted
    }

    private let shortName: String
    private let teamID: String?
    private let accentColor: Color
    private let emphasis: Emphasis
    private let fixedWidth: CGFloat?
    private let logoSize: CGFloat
    private let nameWidth: CGFloat?
    private let foregroundColor: Color?
    @Environment(\.kboFontScale) private var fontScale

    public init(
        shortName: String,
        fullName: String? = nil,
        accentColor: Color,
        emphasis: Emphasis = .normal,
        fixedWidth: CGFloat? = nil,
        logoSize: CGFloat = 20,
        nameWidth: CGFloat? = nil,
        foregroundColor: Color? = nil
    ) {
        self.shortName = shortName
        self.teamID = fullName
        self.accentColor = accentColor
        self.emphasis = emphasis
        self.fixedWidth = fixedWidth
        self.logoSize = logoSize
        self.nameWidth = nameWidth
        self.foregroundColor = foregroundColor
    }

    public var body: some View {
        HStack(spacing: KboSpacingToken.small) {
            teamLogoView

            Text(shortName)
                .font(KboTypographyToken.headline(scaledBy: fontScale))
                .foregroundStyle(teamNameColor)
                .frame(width: nameWidth, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, KboSpacingToken.small)
        .padding(.vertical, 6)
        .frame(width: fixedWidth, alignment: fixedWidth == nil ? .leading : .center)
        .background(accentColor.opacity(emphasis == .highlighted ? 0.36 : 0.24))
        .clipShape(RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KboRadiusToken.pill, style: .continuous)
                .stroke(accentColor.opacity(0.5), lineWidth: emphasis == .highlighted ? 1.5 : 1)
        }
    }

    private var teamNameColor: Color {
        if let foregroundColor {
            return foregroundColor
        }

        guard let teamID, TeamColorResolver.usesLightForeground(forTeamID: teamID) else {
            return accentColor
        }

        return KboColorToken.textPrimary
    }

    @ViewBuilder
    private var teamLogoView: some View {
        if let logoImage = teamLogoImage {
            logoImage
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(accentColor)
                .frame(width: logoSize, height: logoSize)
        }
    }

    private var teamLogoImage: Image? {
        guard let teamID else { return nil }

        if let logoImage = loadPlatformImage(named: teamID) {
            return logoImage
        }

        return nil
    }

    private func loadPlatformImage(named teamID: String) -> Image? {
#if canImport(AppKit)
        if let image = NSImage(named: teamID) {
            return Image(nsImage: image)
        }
#elseif canImport(UIKit)
        if let image = UIImage(named: teamID) {
            return Image(uiImage: image)
        }
#endif

        let logoURL = Bundle.main.url(forResource: teamID, withExtension: "png")
        ?? Bundle.main.url(forResource: teamID, withExtension: "png", subdirectory: "TeamLogos")

        guard let logoURL else { return nil }

#if canImport(AppKit)
        if let image = NSImage(contentsOf: logoURL) {
            return Image(nsImage: image)
        }
#elseif canImport(UIKit)
        if let image = UIImage(contentsOfFile: logoURL.path()) {
            return Image(uiImage: image)
        }
#endif

        return nil
    }
}
