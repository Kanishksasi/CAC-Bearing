import Foundation
import SwiftData
@testable import Bearing

enum OriginalStore {
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

        init() {
            date = Date(timeIntervalSince1970: 12345)
            exerciseRaw = "armRaise"
            acceptedTrials = 3
            rejectedTrials = 1
            leftBest = 110
            leftAverage = 100
        }
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

struct ReminderSlot: Codable, Hashable, Sendable {
    var weekday: Int
    var hour: Int
    var minute: Int
}

@Model
final class CarePlan {
    static let goalRange = 1...14

    var routinesRaw: [String] = []
    var weeklyGoal: Int = 3
    var reminders: [ReminderSlot] = []
    var remindersEnabled: Bool = false

    init(routines: [String] = [], weeklyGoal: Int = 3, reminders: [ReminderSlot] = [], remindersEnabled: Bool = false) {
        self.routinesRaw = routines
        self.weeklyGoal = Self.clamp(weeklyGoal)
        self.reminders = reminders
        self.remindersEnabled = remindersEnabled
    }

    static func clamp(_ goal: Int) -> Int {
        min(max(goal, goalRange.lowerBound), goalRange.upperBound)
    }

}
}
