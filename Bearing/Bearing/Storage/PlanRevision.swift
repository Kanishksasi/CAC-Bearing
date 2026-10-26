import Foundation

struct PlanRevision: Codable, Identifiable, Equatable {
    var id = UUID()
    var number: Int
    var acceptedAt: Date?
    var routines: [Exercise]
    var weeklyGoal: Int
    var reminders: [ReminderSlot]
    var remindersEnabled: Bool
}

extension CarePlan {
    var revisions: [PlanRevision] {
        get { (try? JSONDecoder().decode([PlanRevision].self, from: revisionsData)) ?? [] }
        set { revisionsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var currentRevision: PlanRevision? { revisions.last }

    func recordRevision(at date: Date = .now) {
        var saved = revisions
        let next = PlanRevision(number: (saved.last?.number ?? 0) + 1, acceptedAt: date,
                                routines: routines, weeklyGoal: weeklyGoal, reminders: reminders,
                                remindersEnabled: remindersEnabled)
        if let last = saved.last, last.routines == next.routines, last.weeklyGoal == next.weeklyGoal,
           last.reminders == next.reminders, last.remindersEnabled == next.remindersEnabled { return }
        saved.append(next)
        revisions = saved
        dayChoices = []
    }
    func preserveEarlierPlan() {
        guard revisions.isEmpty, !routines.isEmpty else { return }
        revisions = [PlanRevision(number: 1, acceptedAt: nil, routines: routines, weeklyGoal: weeklyGoal,
                                  reminders: reminders, remindersEnabled: remindersEnabled)]
    }
}

extension Session {
    var planAtRecording: PlanRevision? {
        get { try? JSONDecoder().decode(PlanRevision.self, from: planAtRecordingData) }
        set { planAtRecordingData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
