import SwiftUI

public enum KboMotionToken {
    public static let fastFeedback = Animation.snappy(duration: 0.16)
    public static let sectionReveal = Animation.smooth(duration: 0.28)
    public static let scoreChange = Animation.spring(duration: 0.24, bounce: 0.18)
    public static let livePulse = Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)
}
