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
    public enum Layout: Sendable {
        case horizontal
        case vertical
    }

    private let metrics: [KboMetricValue]
    private let layout: Layout
    @Environment(\.kboFontScale) private var fontScale

    public init(_ metrics: [KboMetricValue], layout: Layout = .horizontal) {
        self.metrics = metrics
        self.layout = layout
    }

    public var body: some View {
        Group {
            switch layout {
            case .horizontal:
                HStack(spacing: 8) {
                    metricCells
                }
            case .vertical:
                VStack(spacing: 8) {
                    metricCells
                }
            }
        }
    }

    @ViewBuilder
    private var metricCells: some View {
        ForEach(metrics) { metric in
            metricCell(metric)
        }
    }

    private func metricCell(_ metric: KboMetricValue) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(metric.title)
                .font(KboTypographyToken.caption(scaledBy: fontScale))
                .foregroundStyle(KboTheme.secondaryText)

            Text(metric.value)
                .font(KboTypographyToken.system(size: 13, weight: .bold, scaledBy: fontScale))
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
