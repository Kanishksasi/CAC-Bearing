import XCTest
import SwiftData
import PDFKit
@testable import Bearing

@MainActor
final class PrivateWorkflowTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian); value.timeZone = TimeZone(secondsFromGMT: 0)!; return value
    }
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    private var monday: Date { date("2026-10-19T10:00:00Z") }
    private func plan() -> CarePlan {
        CarePlan(routines: [.armRaise], reminders: [ReminderSlot(weekday: 2, hour: 9, minute: 0)], remindersEnabled: true)
    }
    private func session(_ time: Date, value: Bool = true, exercise: Exercise = .armRaise) -> Session {
        let record = Session.recorded(exercise: exercise, side: .right, results: value ? [AttemptResult(side: .right, counted: true, peakAngle: 100, reason: nil)] : [])
        record.date = time; return record
    }
    func testTodayCompletionRequiresAValuePlannedRoutineAndPastTimestamp() {
        let p = plan()
        let prior = session(date("2026-10-18T10:00:00Z"))
        let future = session(date("2026-10-19T11:00:00Z"))
        let empty = session(monday, value: false)
        let other = session(monday, exercise: .shoulderReach)
        XCTAssertEqual(TodayPlanService.status(plan: p, sessions: [prior, future, empty, other], now: monday, calendar: calendar), .due)
        XCTAssertEqual(TodayPlanService.status(plan: p, sessions: [session(monday)], now: monday, calendar: calendar), .completed)
    }
    func testSkipUndoAndSnoozeDoNotCreateResults() {
        let p = plan()
        p.chooseToday(skip: true, now: monday, calendar: calendar)
        XCTAssertEqual(TodayPlanService.status(plan: p, sessions: [], now: monday, calendar: calendar), .skipped)
        XCTAssertTrue(TodayPlanService.requests(plan: p, sessions: [], now: monday, calendar: calendar, body: "Private").allSatisfy { !calendar.isDate($0.fireDate!, inSameDayAs: monday) })
        p.chooseToday(now: monday, calendar: calendar)
        XCTAssertEqual(TodayPlanService.status(plan: p, sessions: [], now: monday, calendar: calendar), .due)
        let until = monday.addingTimeInterval(1800)
        p.chooseToday(snooze: until, now: monday, calendar: calendar)
        XCTAssertEqual(TodayPlanService.status(plan: p, sessions: [], now: monday, calendar: calendar), .snoozed(until))
        XCTAssertEqual(TodayPlanService.requests(plan: p, sessions: [], now: monday, calendar: calendar, body: "Private").first?.fireDate, until)
        XCTAssertEqual(TodayPlanService.status(plan: p, sessions: [], now: until.addingTimeInterval(1), calendar: calendar), .due)
    }
    func testCompletionRemovesTodaysNudgeAndPreservesFutureDays() {
        let p = plan()
        let morning = date("2026-10-19T08:00:00Z")
        let before = TodayPlanService.requests(plan: p, sessions: [], now: morning, calendar: calendar, body: "Private")
        XCTAssertTrue(before.contains { calendar.isDate($0.fireDate!, inSameDayAs: morning) })
        let after = TodayPlanService.requests(plan: p, sessions: [session(morning)], now: morning, calendar: calendar, body: "Private")
        XCTAssertFalse(after.contains { calendar.isDate($0.fireDate!, inSameDayAs: morning) })
        XCTAssertFalse(after.isEmpty)
        XCTAssertTrue(after.allSatisfy { $0.fireDate! > morning && $0.body == "Private" })
    }
    func testMidnightSnoozeSurvivesReconciliationNextDay() {
        let p = plan(), late = date("2026-10-19T23:50:00Z"), until = date("2026-10-20T00:20:00Z")
        p.chooseToday(snooze: until, now: late, calendar: calendar)
        let next = TodayPlanService.requests(plan: p, sessions: [], now: date("2026-10-20T00:05:00Z"), calendar: calendar, body: "Private")
        XCTAssertTrue(next.contains { $0.fireDate == until })
    }
    func testPendingRequestsHaveBoundedHorizonAndUniqueIdentifiers() {
        let p = plan()
        p.reminders = (1...7).flatMap { [ReminderSlot(weekday: $0, hour: 12, minute: 0), ReminderSlot(weekday: $0, hour: 12, minute: 0)] }
        let requests = TodayPlanService.requests(plan: p, sessions: [], now: monday, calendar: calendar, body: "Private")
        XCTAssertEqual(requests.count, 28)
        XCTAssertEqual(Set(requests.map(\.identifier)).count, requests.count)
        XCTAssertTrue(requests.allSatisfy { $0.fireDate != nil })
    }
    func testCalendarSchedulingKeepsLocalHourAcrossDaylightSaving() {
        var cal = calendar; cal.timeZone = TimeZone(identifier: "America/Chicago")!
        let p = plan(); p.reminders = [ReminderSlot(weekday: 1, hour: 9, minute: 0)]
        let requests = TodayPlanService.requests(plan: p, sessions: [], now: date("2026-10-25T12:00:00Z"), calendar: cal, body: "Private")
        XCTAssertTrue(requests.count > 1)
        XCTAssertTrue(requests.allSatisfy { cal.component(.hour, from: $0.fireDate!) == 9 })
    }
    func testPlanVersionsPreserveEarlierUnknownDateAndDoNotDuplicateUnchangedPlan() {
        let p = plan(); p.preserveEarlierPlan()
        XCTAssertNil(p.currentRevision?.acceptedAt)
        p.recordRevision(at: monday)
        XCTAssertEqual(p.revisions.count, 1)
        let original = p.currentRevision
        p.weeklyGoal = 5; p.recordRevision(at: monday)
        XCTAssertEqual(p.revisions.count, 2); XCTAssertEqual(p.currentRevision?.number, 2)
        XCTAssertEqual(p.revisions.first, original)
        XCTAssertEqual(p.currentRevision?.acceptedAt, monday)
        p.recordRevision(at: monday); XCTAssertEqual(p.revisions.count, 2)
    }
    func testChangedPlanClearsOlderSnoozeButUnchangedPlanKeepsIt() {
        let p = plan(); p.recordRevision(at: monday)
        p.chooseToday(snooze: monday.addingTimeInterval(1800), now: monday, calendar: calendar)
        p.recordRevision(at: monday)
        XCTAssertEqual(p.dayChoices.count, 1)
        p.weeklyGoal = 5; p.recordRevision(at: monday)
        XCTAssertTrue(p.dayChoices.isEmpty)
    }
    func testRecordSnapshotDoesNotChangeWhenPlanChanges() throws {
        let p = plan(); p.recordRevision(at: monday)
        let record = session(monday); record.planAtRecording = p.currentRevision
        p.weeklyGoal = 6; p.recordRevision(at: monday.addingTimeInterval(60))
        XCTAssertEqual(record.planAtRecording?.weeklyGoal, 3)
        let container = try SessionStore.makeContainer(inMemory: true)
        container.mainContext.insert(p); try SessionStore(context: container.mainContext).save(record)
        let fetched = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Session>()).first)
        XCTAssertEqual(fetched.planAtRecording?.number, 1)
    }
    func testExportScopeExcludesHistoryPlanAndInstructionsUntilChosen() throws {
        Loc.preference = .english; defer { Loc.preference = .system }
        let p = plan(); p.weeklyGoal = 13; p.recordRevision(at: monday)
        let old = session(monday.addingTimeInterval(-86400)); old.countedPeaks = [177, 177]
        let current = session(monday); current.customInstructions = "PRIVATE INSTRUCTIONS"; current.planAtRecording = p.currentRevision
        let bytes = ReportBuilder.data(for: current, in: [old, current], plan: p,
            historyIncluded: false, planIncluded: false, instructionsIncluded: false)
        let text = try XCTUnwrap(PDFDocument(data: bytes)?.string)
        XCTAssertTrue(text.contains("Selected record only"))
        XCTAssertFalse(text.contains("177 degrees")); XCTAssertFalse(text.contains("PRIVATE INSTRUCTIONS"))
        XCTAssertFalse(text.contains("Weekly goal: 13"))
        let included = try XCTUnwrap(PDFDocument(data: ReportBuilder.data(for: current, in: [old, current], plan: p))?.string)
        XCTAssertTrue(included.contains("177 degrees")); XCTAssertTrue(included.contains("PRIVATE INSTRUCTIONS"))
        XCTAssertTrue(included.contains("Weekly goal: 13")); XCTAssertTrue(included.contains("Personal plan at recording"))
    }
    func testLocalExportHistoryIsBoundedAndCannotClaimReceipt() {
        let record = session(monday)
        record.recentExports = (0..<60).map { _ in ReportExport(includesHistory: false, includesPlan: false, includesInstructions: false) }
        XCTAssertEqual(record.recentExports.count, 50)
        XCTAssertTrue(record.recentExports.allSatisfy { $0.handedToAnotherAppAt == nil })
    }
    func testNewLocalStatePersistsAndDeleteAllRemovesIt() throws {
        let container = try SessionStore.makeContainer(inMemory: true), p = plan()
        p.recordRevision(at: monday); p.chooseToday(skip: true, now: monday, calendar: calendar)
        container.mainContext.insert(p)
        let record = session(monday); record.planAtRecording = p.currentRevision
        record.recentExports = [ReportExport(includesHistory: false, includesPlan: true, includesInstructions: false)]
        try SessionStore(context: container.mainContext).save(record)
        let fetched = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<CarePlan>()).first)
        XCTAssertEqual(fetched.dayChoices.count, 1); XCTAssertEqual(fetched.revisions.count, 1)
        try SessionStore(context: container.mainContext).deleteAllData()
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<CarePlan>()), 0)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Session>()), 0)
    }
}

@MainActor
private final class PausedNotificationCenter: NotificationScheduling {
    var requests: [ReminderRequest] = []
    var waiting: CheckedContinuation<Void, Never>?
    var pausedOnce = false
    func authorization() async -> ReminderAuthorization { .allowed }
    func requestAuthorization() async -> Bool { true }
    func schedule(_ request: ReminderRequest) async throws {
        if !pausedOnce {
            pausedOnce = true
            await withCheckedContinuation { waiting = $0 }
        }
        requests.append(request)
    }
    func removeAllPending() { requests = [] }
}

@MainActor
final class ReminderPrivacyRaceTests: XCTestCase {
    func testDeletionInvalidatesAnInFlightReminderRequest() async throws {
        let center = PausedNotificationCenter()
        let plan = CarePlan(routines: [.armRaise], reminders: [ReminderSlot(weekday: 2, hour: 9, minute: 0)], remindersEnabled: true)
        let work = Task { await ReminderScheduler(center: center).sync(plan: plan, body: "Private") }
        for _ in 0..<100 where center.waiting == nil { await Task.yield() }
        guard let continuation = center.waiting else { XCTFail("Scheduler did not reach the controlled pause"); return }
        ReminderScheduler.clearPending()
        continuation.resume()
        let result = await work.value
        XCTAssertEqual(result, .off)
        XCTAssertTrue(center.requests.isEmpty)
    }
    func testNewReconciliationCannotBeOverwrittenByAnOlderRequest() async throws {
        let center = PausedNotificationCenter()
        let first = CarePlan(routines: [.armRaise], reminders: [ReminderSlot(weekday: 2, hour: 9, minute: 0)], remindersEnabled: true)
        let later = CarePlan(routines: [.armRaise], reminders: [ReminderSlot(weekday: 3, hour: 10, minute: 0)], remindersEnabled: true)
        let older = Task { await ReminderScheduler(center: center).sync(plan: first, body: "Old") }
        for _ in 0..<100 where center.waiting == nil { await Task.yield() }
        guard let continuation = center.waiting else { XCTFail("Scheduler did not reach the controlled pause"); return }
        let newer = Task { await ReminderScheduler(center: center).sync(plan: later, body: "New") }
        await Task.yield()
        continuation.resume()
        _ = await older.value; _ = await newer.value
        XCTAssertFalse(center.requests.isEmpty)
        XCTAssertTrue(center.requests.allSatisfy { $0.body == "New" && $0.weekday == 3 })
    }
}

final class AuthenticationReceiptTests: XCTestCase {
    func testNoGrantWithoutAuthenticationAndNoReplay() {
        var grant = AuthenticationReceipt()
        XCTAssertFalse(grant.consume(now: 1))
        grant.issue(now: 2)
        XCTAssertTrue(grant.consume(now: 3))
        XCTAssertFalse(grant.consume(now: 3))
    }
    func testOldOrBackwardClockReceiptCannotOpenRecords() {
        var grant = AuthenticationReceipt()
        grant.issue(now: 2)
        XCTAssertFalse(grant.consume(now: 13))
        grant.issue(now: 20)
        XCTAssertFalse(grant.consume(now: 19))
        XCTAssertFalse(grant.consume(now: 20))
    }
}
