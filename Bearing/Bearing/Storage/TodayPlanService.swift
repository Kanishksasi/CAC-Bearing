import Foundation

struct DayChoice: Codable, Equatable {
    var day: Date
    var skipped: Bool = false
    var snoozedUntil: Date?
}

extension CarePlan {
    var dayChoices: [DayChoice] {
        get { (try? JSONDecoder().decode([DayChoice].self, from: dayChoicesData)) ?? [] }
        set { dayChoicesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    func chooseToday(skip: Bool = false, snooze: Date? = nil, now: Date = .now, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: now)
        var choices = dayChoices.filter { !calendar.isDate($0.day, inSameDayAs: day) && $0.day >= day.addingTimeInterval(-35 * 86400) }
        if skip || snooze != nil { choices.append(DayChoice(day: day, skipped: skip, snoozedUntil: snooze)) }
        dayChoices = choices
    }
}

enum TodayState: Equatable {
    case noPlan, noSchedule, completed, skipped, snoozed(Date), scheduled(Date), due
}

enum TodayPlanService {
    static func completed(plan: CarePlan, sessions: [Session], day: Date, asOf: Date = .now, calendar: Calendar = .current) -> Bool {
        sessions.contains {
            !$0.isLegacy && $0.date <= asOf && $0.value != nil && plan.includes($0.exercise) && calendar.isDate($0.date, inSameDayAs: day)
        }
    }
    static func status(plan: CarePlan?, sessions: [Session], now: Date = .now, calendar: Calendar = .current) -> TodayState {
        guard let plan, !plan.routines.isEmpty else { return .noPlan }
        if completed(plan: plan, sessions: sessions, day: now, asOf: now, calendar: calendar) { return .completed }
        if let choice = plan.dayChoices.first(where: { calendar.isDate($0.day, inSameDayAs: now) }) {
            if choice.skipped { return .skipped }
            if let until = choice.snoozedUntil, until > now { return .snoozed(until) }
        }
        let weekday = calendar.component(.weekday, from: now)
        let times = plan.reminders.filter { $0.weekday == weekday }.compactMap {
            calendar.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: now)
        }.sorted()
        guard let first = times.first else { return .noSchedule }
        return first > now ? .scheduled(first) : .due
    }

    static func requests(plan: CarePlan, sessions: [Session], now: Date, calendar: Calendar = .current,
                         body: String) -> [ReminderRequest] {
        guard plan.remindersEnabled, !plan.routines.isEmpty else { return [] }
        var requests: [ReminderRequest] = []
        let start = calendar.startOfDay(for: now)
        for offset in 0..<28 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  !completed(plan: plan, sessions: sessions, day: day, asOf: now, calendar: calendar) else { continue }
            let choice = plan.dayChoices.first { calendar.isDate($0.day, inSameDayAs: day) }
            if choice?.skipped == true { continue }
            let weekday = calendar.component(.weekday, from: day)
            let slots = plan.reminders.filter { $0.weekday == weekday && (0...23).contains($0.hour) && (0...59).contains($0.minute) }
            var times = slots.compactMap { calendar.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: day) }
            if let snooze = choice?.snoozedUntil { times = [snooze] }
            // Older stores can contain duplicate reminder slots.
            guard let fire = times.sorted().first, fire > now else { continue }
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            requests.append(ReminderRequest(identifier: "bearing.day.\(Int(day.timeIntervalSince1970))",
                weekday: weekday, hour: parts.hour ?? 9, minute: parts.minute ?? 0, body: body, fireDate: fire))
        }
        for choice in plan.dayChoices where choice.day < start && !choice.skipped {
            guard let fire = choice.snoozedUntil, fire > now,
                  !completed(plan: plan, sessions: sessions, day: fire, asOf: now, calendar: calendar),
                  !plan.dayChoices.contains(where: { $0.skipped && calendar.isDate($0.day, inSameDayAs: fire) }) else { continue }
            let parts = calendar.dateComponents([.weekday, .hour, .minute], from: fire)
            requests.append(ReminderRequest(identifier: "bearing.snooze.\(Int(choice.day.timeIntervalSince1970))",
                weekday: parts.weekday ?? 1, hour: parts.hour ?? 9, minute: parts.minute ?? 0, body: body, fireDate: fire))
        }
        var seen = Set<Date>()
        return requests.filter { request in request.fireDate.map { seen.insert($0).inserted } ?? false }
    }
}
