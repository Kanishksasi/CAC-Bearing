import XCTest
import SwiftData
import PDFKit
@testable import Bearing

@MainActor
final class StorageAndReportTests: XCTestCase {
    private func session(_ day: Int, side: Side = .right, peaks: [Double] = [100, 110, 120], reasons: [String] = []) -> Session {
        Session(date: Date(timeIntervalSince1970: Double(day) * 86400), side: side,
                attemptCount: peaks.count + reasons.count, countedPeaks: peaks, notCountedReasons: reasons)
    }
    override func setUp() { Loc.preference = .english }
    override func tearDown() { Loc.preference = .system }

    func testStartingPointUsesMedianOfFirstThreeEligibleSameSideSessions() {
        let data = [session(1, peaks: [100, 100]), session(2, peaks: [110, 110]),
                    session(3, peaks: [120, 120]), session(4, peaks: [150, 150]), session(5, side: .left)]
        XCTAssertNil(BaselineService.baseline(Array(data.prefix(2)), side: .right))
        XCTAssertEqual(BaselineService.baseline(data, side: .right), 110)
        XCTAssertEqual(BaselineService.difference(for: data[3], in: data), 40)
        XCTAssertNil(BaselineService.difference(for: data[1], in: data))
        XCTAssertNil(BaselineService.baseline(data, side: .left))
    }
    func testOneCountedAttemptCannotBuildStartingPoint() {
        let data = (1...5).map { session($0, peaks: [100]) }
        XCTAssertNil(BaselineService.baseline(data, side: .right))
        XCTAssertEqual(BaselineService.sessionsBuilt(data, side: .right), 0)
    }
    func testFutureSessionsCannotChangeHistoricalComparison() {
        let data = [session(1), session(2), session(3), session(4, peaks: [140, 140])]
        XCTAssertNil(BaselineService.difference(for: data[0], in: data))
        let text = PDFDocument(data: ReportBuilder.data(for: data[0], in: data))!.string!
        XCTAssertTrue(text.contains("Building your starting point: 1 of 3 sessions."))
        XCTAssertFalse(text.contains("Your starting point: 110"))
    }
    func testSaveRoundTripAndDeleteAll() throws {
        let container = try SessionStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let saved = session(1, reasons: [NotCountedReason.tilt.rawValue])
        try SessionStore(context: context).save(saved)
        context.insert(UserSettings())
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(fetched.first?.countedPeaks, [100, 110, 120])
        XCTAssertEqual(fetched.first?.notCountedReasons, ["tilt"])
        try SessionStore(context: context).deleteAllData()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Session>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<UserSettings>()), 0)
    }
    func testNumericArraysSurviveClosingAndReopeningStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("roundtrip.store")
        do {
            let container = try SessionStore.makeContainer(url: url)
            try SessionStore(context: container.mainContext).save(session(1, peaks: [101, 103], reasons: ["tilt"]))
        }
        let reopened = try SessionStore.makeContainer(url: url)
        let record = try XCTUnwrap(reopened.mainContext.fetch(FetchDescriptor<Session>()).first)
        XCTAssertEqual(record.countedPeaks, [101, 103])
        XCTAssertEqual(record.notCountedReasons, ["tilt"])
        XCTAssertEqual(record.latest, 102)
    }
    func testOldStoreMigratesWithoutInventingCountedPeaks() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("legacy.store")
        do {
            let schema = Schema([OriginalStore.Session.self, OriginalStore.UserSettings.self, OriginalStore.CarePlan.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            container.mainContext.insert(OriginalStore.Session())
            container.mainContext.insert(OriginalStore.UserSettings(spokenPrompts: false))
            container.mainContext.insert(OriginalStore.CarePlan())
            try container.mainContext.save()
        }
        let migrated = try SessionStore.makeContainer(url: url)
        let sessions = try migrated.mainContext.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].leftBest, 110)
        XCTAssertTrue(sessions[0].isLegacy)
        XCTAssertTrue(sessions[0].countedPeaks.isEmpty)
        XCTAssertNil(BaselineService.baseline(sessions, side: .right))
        XCTAssertEqual(try migrated.mainContext.fetch(FetchDescriptor<UserSettings>()).first?.voiceEnabled, false)
        XCTAssertEqual(migrated.schema.entities.count, 3)
        XCTAssertEqual(try migrated.mainContext.fetchCount(FetchDescriptor<CarePlan>()), 1)
    }
    func testPDFUsesDisplayedSessionRatherThanNewest() throws {
        let old = session(1, peaks: [111, 112], reasons: ["tilt"])
        let newest = session(9, side: .left, peaks: [159, 160])
        let document = try XCTUnwrap(PDFDocument(data: ReportBuilder.data(for: old, in: [old, newest])))
        let text = try XCTUnwrap(document.string)
        XCTAssertTrue(text.contains("Right arm"))
        XCTAssertTrue(text.contains("112 degrees"))
        XCTAssertTrue(text.contains("2 of 3 attempts counted"))
        XCTAssertTrue(text.contains(Strings.reasonTilt))
        XCTAssertTrue(text.contains(Strings.disclaimer))
        XCTAssertFalse(text.contains("160 degrees"))
        XCTAssertEqual(document.page(at: 0)?.bounds(for: .mediaBox).size.width, 612)
    }
    func testPDFDoesNotInventSpreadWithOneAttempt() {
        let one = session(1, peaks: [110])
        let text = PDFDocument(data: ReportBuilder.data(for: one, in: [one]))!.string!
        XCTAssertTrue(text.contains("The spread is not available with one counted attempt."))
        XCTAssertFalse(text.contains("Observed variation:"))
    }
    func testPDFForNoCountedAttemptsAndLongReasonsPaginates() throws {
        let none = session(1, peaks: [], reasons: NotCountedReason.allCases.map(\.rawValue))
        let document = try XCTUnwrap(PDFDocument(data: ReportBuilder.data(for: none, in: [])))
        XCTAssertTrue(document.string!.contains("There is no angle summary for this session."))
        XCTAssertTrue(document.string!.contains(Strings.disclaimer))
        XCTAssertGreaterThan(document.pageCount, 1)
        for index in 0..<document.pageCount {
            let page = try XCTUnwrap(document.page(at: index))
            let image = page.thumbnail(of: CGSize(width: 918, height: 1188), for: .mediaBox)
            let attachment = XCTAttachment(image: image)
            attachment.name = "PDF-page-\(index + 1)"
            attachment.lifetime = .keepAlways
            add(attachment)
            for selection in page.selection(for: page.bounds(for: .mediaBox))?.selectionsByLine() ?? [] {
                let bounds = selection.bounds(for: page)
                XCTAssertGreaterThanOrEqual(bounds.minY, 24)
                XCTAssertLessThanOrEqual(bounds.maxY, 750)
            }
        }
    }
    func testExportsUseUniqueNamesAndDeleteOnlyAppPDFs() throws {
        let data = session(1)
        let first = try ReportBuilder.makePDF(for: data, in: [data])
        let second = try ReportBuilder.makePDF(for: data, in: [data])
        XCTAssertNotEqual(first, second)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let appFile = directory.appendingPathComponent("Bearing-summary-test.pdf")
        let unrelated = directory.appendingPathComponent("Other.pdf")
        try Data().write(to: appFile); try Data().write(to: unrelated)
        try ReportFiles.removeAll(directory: directory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: appFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: unrelated.path))
        try ReportFiles.removeAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: second.path))
    }
}
