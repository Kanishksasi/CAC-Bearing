import Foundation
import SwiftData
@testable import Bearing

enum ArmOnlyStore {

@Model
final class Session {
    var date: Date
    var exerciseRaw: String
    var leftBest: Double?
    var leftAverage: Double?
    var rightBest: Double?
    var rightAverage: Double?
    var standCount: Int?
    var holdSeconds: Double?
    var swayRatio: Double?
    var liftedFootRaw: String?
    var acceptedTrials: Int
    var rejectedTrials: Int

    var sideRaw: String = ""
    var attemptCount: Int = 0
    var countedPeaks: [Double] = []
    var notCountedReasons: [String] = []

    init(date: Date = .now, side: Side, attemptCount: Int, countedPeaks: [Double], notCountedReasons: [String]) {
        self.exerciseRaw = "armRaise"
        self.acceptedTrials = countedPeaks.count
        self.rejectedTrials = notCountedReasons.count
        self.date = date
        self.sideRaw = side.rawValue
        self.attemptCount = attemptCount
        self.countedPeaks = countedPeaks
        self.notCountedReasons = notCountedReasons
    }

    var isLegacy: Bool { sideRaw.isEmpty }
    var side: Side { Side(rawValue: sideRaw) ?? .right }
    var latest: Double? { Geometry.median(countedPeaks) }
    var lowest: Double? { countedPeaks.min() }
    var highest: Double? { countedPeaks.max() }
}

@Model
final class UserSettings {
    var caregiverMode: Bool
    var spokenPrompts: Bool
    var hasSeenIntro: Bool = false
    var countdownSeconds: Int = 3
    var hapticsEnabled: Bool = true
    var speechSpeedRaw: String = "normal"
    var boldSkeleton: Bool = false
    var easyStart: Bool = false
    var languageRaw: String = AppLanguage.system.rawValue

    init(caregiverMode: Bool = false, spokenPrompts: Bool = true, hasSeenIntro: Bool = false) {
        self.caregiverMode = caregiverMode
        self.spokenPrompts = spokenPrompts
        self.hasSeenIntro = hasSeenIntro
    }
}

}
