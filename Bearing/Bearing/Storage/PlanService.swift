import Foundation

struct WeekCount: Equatable, Sendable {
    var weekStart: Date
    var done: Int
    var goal: Int
}

// Plan weeks run Monday to Sunday in the phone's calendar.
enum PlanService {
    static func mondayCalendar(_ base: Calendar = .current) -> Calendar {
        var calendar = base
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    static func weekStart(of date: Date, calendar: Calendar = .current) -> Date {
        let monday = mondayCalendar(calendar)
        return monday.dateInterval(of: .weekOfYear, for: date)?.start ?? monday.startOfDay(for: date)
    }

    static func checkIns(inWeekOf date: Date,
                         sessions: [Session],
                         routines: [Exercise],
                         calendar: Calendar = .current) -> Int {
        let monday = mondayCalendar(calendar)
        guard let week = monday.dateInterval(of: .weekOfYear, for: date) else { return 0 }
        return sessions.filter { !$0.isLegacy && routines.contains($0.exercise) && $0.value != nil && $0.date >= week.start && $0.date < week.end }.count
    }

    static func thisWeek(plan: CarePlan, sessions: [Session], now: Date = Date(), calendar: Calendar = .current) -> WeekCount {
        WeekCount(weekStart: weekStart(of: now, calendar: calendar),
                  done: checkIns(inWeekOf: now, sessions: sessions, routines: plan.routines, calendar: calendar),
                  goal: plan.weeklyGoal)
    }

    // Older goals are not stored, so each week uses the current goal.
    static func recentWeeks(plan: CarePlan,
                            sessions: [Session],
                            count: Int = 4,
                            now: Date = Date(),
                            calendar: Calendar = .current) -> [WeekCount] {
        let monday = mondayCalendar(calendar)
        let current = weekStart(of: now, calendar: calendar)
        return (0..<count).reversed().compactMap { back in
            guard let start = monday.date(byAdding: .weekOfYear, value: -back, to: current) else { return nil }
            return WeekCount(weekStart: start,
                             done: checkIns(inWeekOf: start, sessions: sessions, routines: plan.routines, calendar: calendar),
                             goal: plan.weeklyGoal)
        }
    }

    static func weekLine(_ week: WeekCount) -> String {
        Loc.f("This week: %lld of %lld check-ins", week.done, week.goal)
    }
}
