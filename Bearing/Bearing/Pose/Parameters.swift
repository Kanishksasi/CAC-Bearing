import Foundation

// These are tracking settings, not health cutoffs.
enum Parameters {
    static let tiltLimitDegrees = 5.0

    static let shoulderHipConfidence: Float = 0.3
    static let elbowConfidence: Float = 0.5

    static let smoothingTau = 0.065 // seconds; about 0.4 alpha at 30 fps
    static let maxHeldFrames = 2
    static let minFrameInterval = 0.030

    static let attemptSeconds = 6.0
    static let peakWindowSeconds = 0.5
    static let minValidFrameFraction = 0.8
    static let minValidRateHz = 15.0
    static let maxGapSeconds = 0.25
    static let maxJumpAcrossGapDegrees = 25.0
    static let jumpGapSeconds = 0.1
    static let startLowDegrees = 40.0
    static let endLowDegrees = 40.0
    static let trunkLeanLimitDegrees = 10.0
    static let minRaiseDegrees = 60.0
    static let attemptsPerSide = 3
    static let countdownSeconds = 3
    static let tiltStaleSeconds = 0.5
    static let stableSeconds = 1.0
    static let speechMinIntervalSeconds = 2.0
    static let speechRepeatSeconds = 6.0
    static let holdToStartSeconds = 1.0
    static let topSamplesForPeak = 5

    static let edgeMargin = 0.02 // fraction of the frame
    static let spanMin = 0.18 // shoulder-to-hip span divided by frame height
    static let spanMax = 0.40
    static let stableMaxMove = 0.03 // fraction of frame width and height over one second

    static let sitToStandSeconds = 30.0
    static let standCalibrationSeconds = 0.5
    static let standRise = 0.5
    static let sitReturn = 0.2
    static let balanceMaxSeconds = 15.0
    static let balanceHoldCap = 10.0
    static let balanceLiftStart = 0.08
    static let balanceLiftEnd = 0.04
    static let kneeLowDegrees = 20.0
    static let kneeRaiseDegrees = 30.0

    static let baselineSessions = 3
    static let minCountedForBaseline = 2
}
