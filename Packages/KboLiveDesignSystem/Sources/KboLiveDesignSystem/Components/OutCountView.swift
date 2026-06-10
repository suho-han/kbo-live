import SwiftUI

public struct OutCountView: View {
    private let outs: Int

    public init(outs: Int) {
        self.outs = min(max(outs, 0), 3)
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < outs ? KboColorToken.statusLive : KboColorToken.borderMuted)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, KboSpacingToken.xSmall)
        .padding(.vertical, 4)
    }
}
