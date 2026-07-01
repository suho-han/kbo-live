import Foundation

public struct BackendPresetPolicy<Preset: Hashable & Sendable>: Sendable {
    public let displayOrder: [Preset]

    private let selectablePresets: Set<Preset>

    public init(
        displayOrder: [Preset],
        selectablePresets: some Sequence<Preset>
    ) {
        self.displayOrder = displayOrder
        self.selectablePresets = Set(selectablePresets)
    }

    public func isSelectable(_ preset: Preset) -> Bool {
        selectablePresets.contains(preset)
    }
}
