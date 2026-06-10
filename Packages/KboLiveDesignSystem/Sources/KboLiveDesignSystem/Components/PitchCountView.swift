import SwiftUI

public struct PitchCountView: View {
    private let balls: Int
    private let strikes: Int

    public init(balls: Int, strikes: Int) {
        self.balls = max(0, balls)
        self.strikes = max(0, strikes)
    }

    public var body: some View {
        Text("B \(balls) · S \(strikes)")
            .font(KboTypographyToken.footnote)
            .foregroundStyle(KboTheme.secondaryText)
            .monospacedDigit()
    }
}
