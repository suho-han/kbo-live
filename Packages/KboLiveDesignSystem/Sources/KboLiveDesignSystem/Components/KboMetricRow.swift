import SwiftUI

public struct KboMetricValue: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let value: String
    public let tint: Color?

    public init(title: String, value: String, tint: Color? = nil) {
        self.id = title
        self.title = title
        self.value = value
        self.tint = tint
    }
}

public struct KboMetricRow: View {
    private let metrics: [KboMetricValue]

    public init(_ metrics: [KboMetricValue]) {
        self.metrics = metrics
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 3) {
                    Text(metric.title)
                        .font(KboTypographyToken.caption)
                        .foregroundStyle(KboTheme.secondaryText)

                    Text(metric.value)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(metric.tint ?? KboTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(KboSurfaceToken.glassControl)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(KboSurfaceToken.glassBorder.opacity(0.7), lineWidth: 1)
                }
            }
        }
    }
}
