import Testing
@testable import BaseballLiveKRCore

struct BackendPresetPolicyTests {
    private enum TestPreset: Hashable, Sendable {
        case production
        case staging
        case local
    }

    @Test func displayOrderPreservesConfiguredPriority() {
        let policy = BackendPresetPolicy<TestPreset>(
            displayOrder: [.production, .staging, .local],
            selectablePresets: [.production]
        )

        #expect(policy.displayOrder == [.production, .staging, .local])
    }

    @Test func onlyConfiguredPresetsRemainSelectable() {
        let policy = BackendPresetPolicy<TestPreset>(
            displayOrder: [.production, .staging, .local],
            selectablePresets: [.production]
        )

        #expect(policy.isSelectable(.production))
        #expect(policy.isSelectable(.staging) == false)
        #expect(policy.isSelectable(.local) == false)
    }
}
