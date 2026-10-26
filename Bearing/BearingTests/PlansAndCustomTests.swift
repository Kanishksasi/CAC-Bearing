import XCTest
import SwiftData
import PDFKit
@testable import Bearing

@MainActor
final class PlansAndCustomTests: XCTestCase {
    override func setUp() { Loc.preference = .english }
    override func tearDown() { Loc.preference = .system }

    func testTemplatesPersistAndDeletingAllRemovesThePlan() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("custom.store")
        let template = CustomCheckIn(name: "My seated count", instructions: "Use the instructions I already have.", exercise: .manualCount)
        do {
            let container = try SessionStore.makeContainer(url: url)
            let plan = CarePlan(routines: [.manualCount], weeklyGoal: 4)
            plan.customCheckIns = [template]; container.mainContext.insert(plan); try container.mainContext.save()
        }
        let reopened = try SessionStore.makeContainer(url: url)
        let plan = try XCTUnwrap(reopened.mainContext.fetch(FetchDescriptor<CarePlan>()).first)
        XCTAssertEqual(plan.customCheckIns, [template]); XCTAssertEqual(plan.weeklyGoal, 4)
        try SessionStore(context: reopened.mainContext).deleteAllData()
        XCTAssertEqual(try reopened.mainContext.fetchCount(FetchDescriptor<CarePlan>()), 0)
    }
    func testPreviousArmOnlyStoreMigratesIntoExpandedSchema() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("arm-only.store")
        do {
            let schema = Schema([ArmOnlyStore.Session.self, ArmOnlyStore.UserSettings.self])
            let store = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            store.mainContext.insert(ArmOnlyStore.Session(side: .left, attemptCount: 3, countedPeaks: [95, 100, 105], notCountedReasons: []))
            let preferences = ArmOnlyStore.UserSettings(spokenPrompts: false)
            preferences.languageRaw = "es"
            store.mainContext.insert(preferences)
            try store.mainContext.save()
        }
        let expanded = try SessionStore.makeContainer(url: url)
        let record = try XCTUnwrap(expanded.mainContext.fetch(FetchDescriptor<Session>()).first)
        XCTAssertFalse(record.isLegacy); XCTAssertEqual(record.latest, 100); XCTAssertEqual(record.side, .left)
        XCTAssertEqual(record.customID, "")
        let preferences = try XCTUnwrap(expanded.mainContext.fetch(FetchDescriptor<UserSettings>()).first)
        XCTAssertFalse(preferences.voiceEnabled); XCTAssertEqual(preferences.languageRaw, "es")
        let plan = CarePlan(); expanded.mainContext.insert(plan); try expanded.mainContext.save()
        XCTAssertEqual(try expanded.mainContext.fetchCount(FetchDescriptor<CarePlan>()), 1)
    }

    func testBalanceHistoryKeepsTheLiftedFootSeparate() {
        let left = Session.recorded(exercise: .balance, side: .left,
            results: [AttemptResult(side: .left, counted: true, peakAngle: nil, reason: nil, holdSeconds: 8, liftedFoot: .left)])
        let right = Session.recorded(exercise: .balance, side: .right,
            results: [AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil, holdSeconds: 10, liftedFoot: .right)])
        left.date = Date(timeIntervalSince1970: 0); right.date = Date(timeIntervalSince1970: 100)
        XCTAssertEqual(TrendService.series(for: right, in: [left, right]).count, 1)
        XCTAssertEqual(BaselineService.comparable(to: right, in: [left, right]).count, 1)
    }

    func testCustomValidationRejectsBlankNameAndInvalidTimer() {
        XCTAssertFalse(CustomCheckIn(name: "  ", instructions: "", exercise: .manualCount).isValid)
        XCTAssertFalse(CustomCheckIn(name: "Timer", instructions: "", exercise: .manualTimer, timerSeconds: 0).isValid)
        XCTAssertTrue(CustomCheckIn(name: "Timer", instructions: "", exercise: .manualTimer, timerSeconds: 60).isValid)
    }
    func testManualTimerExcludesPausedTimeAndCapsAndResets() {
        var timer = ManualTimerState(limit: 10)
        timer.start(now: 100); XCTAssertEqual(timer.tick(now: 102), 2)
        timer.pause(now: 103); XCTAssertEqual(timer.elapsed(now: 1000), 3)
        timer.start(now: 1000); XCTAssertEqual(timer.tick(now: 1002), 5)
        XCTAssertEqual(timer.tick(now: 1020), 10); XCTAssertFalse(timer.running)
        timer.reset(); XCTAssertEqual(timer.elapsed(now: 2000), 0)
        timer.start(now: .nan); XCTAssertFalse(timer.running)
    }
    func testManualSessionSnapshotsNameAndInstructionsAndPDFMarksItsSource() {
        var template = CustomCheckIn(name: "My count", instructions: "My existing instructions.", exercise: .manualCount)
        let result = AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil, repetitions: 8)
        let session = Session.recorded(exercise: .manualCount, side: .right, results: [result], template: template)
        template.name = "Edited count"; template.instructions = "Changed instructions."
        XCTAssertEqual(session.customTitle, "My count"); XCTAssertEqual(session.customInstructions, "My existing instructions.")
        XCTAssertEqual(session.value, 8); XCTAssertNil(session.latest); XCTAssertFalse(session.isLegacy)
        let text = PDFDocument(data: ReportBuilder.data(for: session, in: [session]))!.string!
        XCTAssertTrue(text.contains("Manual entry")); XCTAssertTrue(text.contains("8 repetitions"))
        XCTAssertTrue(text.contains("My existing instructions.")); XCTAssertTrue(text.contains(Strings.disclaimer))
    }
    func testCameraTemplateCanRecordOtherSideWithoutLosingItsIdentity() throws {
        var template = CustomCheckIn(name: "My arm routine", instructions: "My saved instructions.", exercise: .armRaise)
        let results = [AttemptResult(side: .right, counted: true, peakAngle: 90, reason: nil),
                       AttemptResult(side: .right, counted: true, peakAngle: 100, reason: nil)]
        let right = Session.recorded(exercise: .armRaise, side: .right, results: results, template: template)
        template.name = "A changed name"
        let snapshot = try XCTUnwrap(right.cameraTemplateSnapshot)
        let left = Session.recorded(exercise: .armRaise, side: .left, results: results, template: snapshot)
        left.date = right.date.addingTimeInterval(1)
        XCTAssertEqual(left.customID, right.customID)
        XCTAssertEqual(left.customTitle, "My arm routine")
        XCTAssertEqual(left.customInstructions, "My saved instructions.")
        XCTAssertEqual(TrendService.series(for: left, in: [left, right]).count, 1)
    }

    func testComparisonsAndChartsKeepRoutineSideAndCustomIdentitySeparate() {
        let template = CustomCheckIn(name: "Count one", instructions: "", exercise: .manualCount)
        let other = CustomCheckIn(name: "Count two", instructions: "", exercise: .manualCount)
        func record(_ value: Int, day: Int, template: CustomCheckIn) -> Session {
            let s = Session.recorded(exercise: .manualCount, side: .right,
                                     results: [AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil, repetitions: value)], template: template)
            s.date = Date(timeIntervalSince1970: Double(day) * 86400); return s
        }
        let mine = [record(5, day: 1, template: template), record(7, day: 2, template: template),
                    record(6, day: 3, template: template), record(9, day: 4, template: template)]
        let unrelated = record(999, day: 1, template: other)
        let all = mine + [unrelated]
        XCTAssertEqual(BaselineService.startingPoint(for: mine[3], in: all), 6)
        XCTAssertEqual(BaselineService.change(for: mine[3], in: all), 3)
        XCTAssertNil(BaselineService.change(for: mine[0], in: all))
        XCTAssertEqual(TrendService.series(for: mine[3], in: all).count, 4)
        XCTAssertEqual(TrendService.series(for: mine[0], in: all).count, 1)
        XCTAssertNil(BaselineService.baseline(all, side: .right))
    }
    func testAngleBaselinesExcludeOtherExercisesAndSides() {
        let mine = (1...3).map { day -> Session in
            let s = Session.recorded(exercise: .kneeBend, side: .left,
                                    results: [AttemptResult(side: .left, counted: true, peakAngle: 50, reason: nil),
                                              AttemptResult(side: .left, counted: true, peakAngle: 60, reason: nil)])
            s.date = Date(timeIntervalSince1970: Double(day) * 86400); return s
        }
        let other = Session(side: .right, attemptCount: 3, countedPeaks: [150, 160, 170], notCountedReasons: [])
        XCTAssertEqual(BaselineService.startingPoint(for: mine[2], in: mine + [other]), 55)
        XCTAssertNil(BaselineService.baseline(mine, side: .left))
    }
    func testWeeklyCountUsesMondayAndExcludesEmptyAndUnplannedRecordsAtEndBoundary() {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1760947200)
        let start = PlanService.weekStart(of: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.weekday, from: start), 2)
        let record = Session.recorded(exercise: .sitToStand, side: .right,
                                      results: [AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil, repetitions: 0)])
        record.date = start
        let end = Session.recorded(exercise: .sitToStand, side: .right,
                                   results: [AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil, repetitions: 3)])
        end.date = calendar.date(byAdding: .day, value: 7, to: start)!
        let empty = Session.recorded(exercise: .sitToStand, side: .right, results: [])
        empty.date = start
        XCTAssertEqual(PlanService.checkIns(inWeekOf: now, sessions: [record, end, empty], routines: [.sitToStand], calendar: calendar), 1)
        XCTAssertEqual(PlanService.checkIns(inWeekOf: now, sessions: [record], routines: [.armRaise], calendar: calendar), 0)
        XCTAssertEqual(CarePlan.clamp(999), 14)
    }
    func testRestoredCountAndHoldPDFsIncludeUnitsAndReasons() {
        for exercise in [Exercise.sitToStand, .balance] {
            let result = AttemptResult(side: .left, counted: true, peakAngle: nil, reason: nil,
                                       repetitions: exercise == .sitToStand ? 4 : nil,
                                       holdSeconds: exercise == .balance ? 8 : nil,
                                       swayRatio: exercise == .balance ? 0.03 : nil, liftedFoot: exercise == .balance ? .left : nil)
            let record = Session.recorded(exercise: exercise, side: .left, results: [result])
            let text = PDFDocument(data: ReportBuilder.data(for: record, in: [record]))!.string!
            XCTAssertTrue(text.contains(exercise.title)); XCTAssertTrue(text.contains(record.valueText))
            XCTAssertTrue(text.contains(Strings.disclaimer))
            if exercise == .balance { XCTAssertTrue(text.contains("Left foot lifted")); XCTAssertTrue(text.contains("Sway:")) }
        }
    }
}

@MainActor
private final class FakeNotifications: NotificationScheduling {
    var status = ReminderAuthorization.notAsked
    var grant = true
    var askCount = 0
    var requests: [ReminderRequest] = []
    var shouldThrow = false
    func authorization() async -> ReminderAuthorization { status }
    func requestAuthorization() async -> Bool { askCount += 1; status = grant ? .allowed : .denied; return grant }
    func schedule(_ request: ReminderRequest) async throws {
        if shouldThrow { throw CocoaError(.fileWriteUnknown) }
        requests.append(request)
    }
    func removeAllPending() { requests = [] }
}

@MainActor
final class ReminderSchedulerTests: XCTestCase {
    func testValidatesAndDeduplicatesReminderSlots() {
        let slot = ReminderSlot(weekday: 2, hour: 9, minute: 0)
        let requests = ReminderScheduler.requests(for: [slot, slot, ReminderSlot(weekday: 9, hour: 99, minute: 0)], body: "Reminder")
        XCTAssertEqual(requests.count, 1); XCTAssertEqual(requests.first?.weekday, 2)
    }
    func testPermissionIsRequestedOnlyWhenEnablingAndTurningOffClears() async {
        let center = FakeNotifications(), plan = CarePlan(routines: [.armRaise], reminders: [ReminderSlot(weekday: 2, hour: 9, minute: 0)])
        let scheduler = ReminderScheduler(center: center)
        _ = await scheduler.sync(plan: plan, body: "Reminder"); XCTAssertEqual(center.askCount, 0)
        let enabled = await scheduler.turnOn(plan: plan, body: "Reminder")
        XCTAssertTrue(enabled); XCTAssertEqual(center.askCount, 1); XCTAssertFalse(center.requests.isEmpty)
        XCTAssertTrue(center.requests.allSatisfy { $0.fireDate != nil })
        await scheduler.turnOff(plan: plan, body: "Reminder")
        XCTAssertTrue(center.requests.isEmpty); XCTAssertFalse(plan.remindersEnabled)
    }
    func testDenialAndSchedulingFailureDoNotLeaveReminderEnabled() async {
        let center = FakeNotifications(); center.grant = false
        let plan = CarePlan(routines: [.armRaise], reminders: [ReminderSlot(weekday: 3, hour: 10, minute: 0)])
        let scheduler = ReminderScheduler(center: center)
        let denied = await scheduler.turnOn(plan: plan, body: "Reminder")
        XCTAssertFalse(denied); XCTAssertFalse(plan.remindersEnabled)
        center.status = .allowed; center.shouldThrow = true
        let failed = await scheduler.turnOn(plan: plan, body: "Reminder")
        XCTAssertFalse(failed); XCTAssertFalse(plan.remindersEnabled); XCTAssertTrue(center.requests.isEmpty)
    }
}
