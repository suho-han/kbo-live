import SwiftUI

public struct KboPrimaryActionButton: View {
    private let title: String
    private let systemImage: String?
    private let tint: Color
    private let isDisabled: Bool
    private let action: () -> Void
    @Environment(\.kboFontScale) private var fontScale

    public init(
        title: String,
        systemImage: String? = nil,
        tint: Color = KboSemanticColorToken.accentBlue,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(KboTypographyToken.system(size: 14, weight: .bold, scaledBy: fontScale))
                }

                Text(title)
                    .font(KboTypographyToken.system(size: 13, weight: .bold, scaledBy: fontScale))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: KboControlToken.primaryButtonHeight)
            .background(
                LinearGradient(
                    colors: [
                        tint.opacity(isDisabled ? 0.34 : 0.95),
                        tint.opacity(isDisabled ? 0.24 : 0.70)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(KboSurfaceToken.glassBorder.opacity(isDisabled ? 0.45 : 0.8), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.72 : 1)
    }
}
