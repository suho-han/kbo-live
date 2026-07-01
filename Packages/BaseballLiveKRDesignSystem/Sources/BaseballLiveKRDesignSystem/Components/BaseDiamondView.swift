import SwiftUI

public struct BaseDiamondView: View {
    private let firstOccupied: Bool
    private let secondOccupied: Bool
    private let thirdOccupied: Bool

    public init(firstOccupied: Bool, secondOccupied: Bool, thirdOccupied: Bool) {
        self.firstOccupied = firstOccupied
        self.secondOccupied = secondOccupied
        self.thirdOccupied = thirdOccupied
    }

    public var body: some View {
        ZStack {
            DiamondBase(isOccupied: secondOccupied)
                .offset(y: -10)

            DiamondBase(isOccupied: thirdOccupied)
                .offset(x: -10)

            DiamondBase(isOccupied: firstOccupied)
                .offset(x: 10)
        }
        .frame(width: 36, height: 28)
    }
}

private struct DiamondBase: View {
    let isOccupied: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(isOccupied ? KboColorToken.statusScheduled : Color.clear)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(45))
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(KboColorToken.borderMuted, lineWidth: 1)
                    .rotationEffect(.degrees(45))
            }
    }
}
