import Foundation
import UserNotifications

enum ReminderAuthorization: Equatable, Sendable {
    case notAsked, allowed, denied
}

struct ReminderRequest: Equatable, Sendable {
    let identifier: String
    let weekday: Int
    let hour: Int
    let minute: Int
    let body: String
    var fireDate: Date? = nil
}

@MainActor
protocol NotificationScheduling {
    func authorization() async -> ReminderAuthorization
    func requestAuthorization() async -> Bool
    func schedule(_ request: ReminderRequest) async throws
    func removeAllPending()
    func removeDelivered()
}

extension NotificationScheduling { func removeDelivered() {} }

@MainActor
struct SystemNotificationCenter: NotificationScheduling {
    private var center: UNUserNotificationCenter { .current() }

    func authorization() async -> ReminderAuthorization {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .allowed
        case .denied: return .denied
        default: return .notAsked
        }
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ request: ReminderRequest) async throws {
        let content = UNMutableNotificationContent()
        content.body = request.body
        content.sound = .default
        var parts = DateComponents()
        parts.weekday = request.weekday
        parts.hour = request.hour
        parts.minute = request.minute
        if let fire = request.fireDate { parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire) }
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: request.fireDate == nil)
        try await center.add(UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger))
    }

    func removeAllPending() { center.removeAllPendingNotificationRequests() }
    func removeDelivered() { center.removeAllDeliveredNotifications() }
}

enum ReminderOutcome: Equatable {
    case off
    case failed
    case scheduled(Int)
    case notAllowed
}

@MainActor
struct ReminderScheduler {
    let center: NotificationScheduling
    private static var generation = 0
    private static var pending: Task<ReminderOutcome, Never>?

    static func clearPending() {
        generation += 1
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    static func requests(for slots: [ReminderSlot], body: String) -> [ReminderRequest] {
        var seen = Set<ReminderSlot>()
        return slots.compactMap { slot in
            guard (1...7).contains(slot.weekday), (0...23).contains(slot.hour), (0...59).contains(slot.minute),
                  seen.insert(slot).inserted else { return nil }
            return ReminderRequest(identifier: "bearing.reminder.\(slot.weekday).\(slot.hour).\(slot.minute)",
                                   weekday: slot.weekday, hour: slot.hour, minute: slot.minute, body: body)
        }
    }

    @discardableResult
    func sync(plan: CarePlan?, body: String, sessions: [Session] = [], now: Date = .now) async -> ReminderOutcome {
        Self.generation += 1
        let token = Self.generation
        let previous = Self.pending
        let task = Task { @MainActor in
            _ = await previous?.value
            guard Self.generation == token else { return ReminderOutcome.off }
            return await performSync(plan: plan, body: body, sessions: sessions, now: now, token: token)
        }
        Self.pending = task
        return await task.value
    }

    private func performSync(plan: CarePlan?, body: String, sessions: [Session], now: Date, token: Int) async -> ReminderOutcome {
        center.removeAllPending()
        center.removeDelivered()
        guard let plan, plan.remindersEnabled else { return .off }
        let authorization = await center.authorization()
        guard token == Self.generation else { center.removeAllPending(); return .off }
        guard authorization == .allowed else { return .notAllowed }
        var count = 0
        for request in TodayPlanService.requests(plan: plan, sessions: sessions, now: now, body: body) {
            do {
                try await center.schedule(request)
                guard token == Self.generation else { center.removeAllPending(); return .off }
                count += 1
            } catch {
                center.removeAllPending()
                guard token == Self.generation else { return .off }
                plan.remindersEnabled = false
                return .failed
            }
        }
        return .scheduled(count)
    }

    func turnOn(plan: CarePlan, body: String, sessions: [Session] = []) async -> Bool {
        guard !plan.routines.isEmpty else { plan.remindersEnabled = false; return false }
        switch await center.authorization() {
        case .denied:
            center.removeAllPending()
            plan.remindersEnabled = false
            return false
        case .notAsked:
            guard await center.requestAuthorization() else {
                center.removeAllPending()
                plan.remindersEnabled = false
                return false
            }
        case .allowed:
            break
        }
        plan.remindersEnabled = true
        let result = await sync(plan: plan, body: body, sessions: sessions)
        guard case .scheduled = result else { plan.remindersEnabled = false; return false }
        return true
    }

    func turnOff(plan: CarePlan, body: String) async {
        plan.remindersEnabled = false
        await sync(plan: plan, body: body)
    }
}
