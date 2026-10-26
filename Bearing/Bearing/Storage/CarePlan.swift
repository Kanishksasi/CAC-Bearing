import Foundation
import SwiftData

// Calendar weekdays use 1 for Sunday through 7 for Saturday.
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
    var revisionsData: Data = Data()
    var dayChoicesData: Data = Data()
    var customTemplatesData: Data = Data()

    init(routines: [Exercise] = [], weeklyGoal: Int = 3, reminders: [ReminderSlot] = [], remindersEnabled: Bool = false) {
        self.routinesRaw = routines.map(\.rawValue)
        self.weeklyGoal = Self.clamp(weeklyGoal)
        self.reminders = reminders
        self.remindersEnabled = remindersEnabled
    }

    static func clamp(_ goal: Int) -> Int {
        min(max(goal, goalRange.lowerBound), goalRange.upperBound)
    }

    var routines: [Exercise] {
        get { Exercise.allCases.filter { routinesRaw.contains($0.rawValue) } }
        set { routinesRaw = Exercise.allCases.filter { newValue.contains($0) }.map(\.rawValue) }
    }

    var customCheckIns: [CustomCheckIn] {
        get { (try? JSONDecoder().decode([CustomCheckIn].self, from: customTemplatesData)) ?? [] }
        set { customTemplatesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    func includes(_ exercise: Exercise) -> Bool { routinesRaw.contains(exercise.rawValue) }
}

extension CarePlan {
    static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]
    static let defaultReminderDays: Set<Int> = [2, 4, 6]
    static let defaultReminderTime = (hour: 9, minute: 0)

    var reminderWeekdays: Set<Int> { Set(reminders.map(\.weekday)) }

    var reminderTime: (hour: Int, minute: Int) {
        reminders.first.map { ($0.hour, $0.minute) } ?? Self.defaultReminderTime
    }

    func setReminders(days: Set<Int>, hour: Int, minute: Int) {
        reminders = Self.weekdayOrder.filter { days.contains($0) }
            .map { ReminderSlot(weekday: $0, hour: hour, minute: minute) }
    }
}

enum ReminderText {
    static var body: String { Loc.t("Time for your Bearing check-in.") }
    static var reason: String { Loc.t("Bearing needs your permission to show a reminder at the times you pick. Reminders stay on your phone.") }
    static var deniedTitle: String { Loc.t("Reminders are off") }
    static var deniedHelp: String { Loc.t("To get reminders, turn on notifications for Bearing in Settings.") }
}
