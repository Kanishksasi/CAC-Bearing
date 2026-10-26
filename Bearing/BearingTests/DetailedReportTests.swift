import XCTest
import PDFKit
import SwiftData
@testable import Bearing

@MainActor
final class DetailedReportTests: XCTestCase {
    override func setUp() { Loc.preference = .english }
    override func tearDown() { Loc.preference = .system }

    private func record(_ day: Int, custom: CustomCheckIn? = nil) -> Session {
        var first = AttemptResult(side: .right, counted: true, peakAngle: 101, reason: nil)
        first.durationSeconds = 6
        var second = AttemptResult(side: .right, counted: false, peakAngle: nil, reason: .tilt)
        second.durationSeconds = 6.1
        var third = AttemptResult(side: .right, counted: true, peakAngle: 121, reason: nil)
        third.durationSeconds = 6.2
        let session = Session.recorded(exercise: .armRaise, side: .right, results: [first, second, third], template: custom, cameraSource: "front")
        session.date = Date(timeIntervalSince1970: Double(day) * 86400)
        return session
    }
    private func text(_ bytes: Data) throws -> String {
        try XCTUnwrap(PDFDocument(data: bytes)?.string).split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    func testNewDetailsPersistOrderedAttemptsWithoutRejectedAngles() throws {
        let container = try SessionStore.makeContainer(inMemory: true)
        let session = record(1)
        try SessionStore(context: container.mainContext).save(session)
        let stored = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Session>()).first)
        let details = try XCTUnwrap(stored.reportDetails)
        XCTAssertEqual(details.attempts.map(\.number), [1, 2, 3])
        XCTAssertEqual(details.attempts.map(\.counted), [true, false, true])
        XCTAssertNil(details.attempts[1].angle)
        XCTAssertEqual(details.attempts[1].reason, "tilt")
        XCTAssertEqual(details.attempts[2].durationSeconds, 6.2)
        XCTAssertEqual(details.source, "front")
        XCTAssertEqual(details.protocolVersion, "bearing-4")
    }
    func testReportContainsAllFourSectionsAndAttemptOrder() throws {
        let session = record(5)
        let report = try text(ReportBuilder.data(for: session, in: [session]))
        for section in ["Record overview", "Attempts and recording details", "Personal comparison and history", "Plan context and review notes"] {
            XCTAssertTrue(report.contains(section), section)
        }
        let a = try XCTUnwrap(report.range(of: "Attempt 1:"))
        let b = try XCTUnwrap(report.range(of: "Attempt 2:"))
        let c = try XCTUnwrap(report.range(of: "Attempt 3:"))
        XCTAssertLessThan(a.lowerBound, b.lowerBound); XCTAssertLessThan(b.lowerBound, c.lowerBound)
        XCTAssertTrue(report.contains("Front camera"))
        XCTAssertTrue(report.contains("6.2 seconds"))
        XCTAssertTrue(report.contains("Frame rate, joint coverage, and phone angles were not saved as separate measurements."))
    }
    func testOlderRecordsDoNotInventOrderCameraOrDuration() throws {
        let session = Session(side: .left, attemptCount: 3, countedPeaks: [75, 95], notCountedReasons: ["tilt"])
        let report = try text(ReportBuilder.data(for: session, in: [session]))
        XCTAssertTrue(report.contains("The original order of attempts was not saved for this record."))
        XCTAssertTrue(report.contains("Camera or entry source: Not saved"))
        XCTAssertFalse(report.contains("Attempt 1:"))
        XCTAssertFalse(report.contains("Front camera"))
    }
    func testMatchingHistoryIncludesMissingValuesButExcludesFutureOtherSideAndCustom() throws {
        let previous = record(1), chosen = record(3)
        let future = record(5); future.countedPeaks = [177, 177]
        let otherSide = record(2); otherSide.sideRaw = "left"; otherSide.countedPeaks = [166, 166]
        let custom = record(2, custom: CustomCheckIn(name: "Another template", instructions: "", exercise: .armRaise))
        custom.countedPeaks = [155, 155]
        let missing = Session(date: Date(timeIntervalSince1970: 86400 * 2), side: .right,
                              attemptCount: 1, countedPeaks: [], notCountedReasons: ["tilt"])
        let report = try text(ReportBuilder.data(for: chosen, in: [previous, chosen, future, otherSide, custom, missing]))
        XCTAssertTrue(report.contains("Showing 3 of 3 matching records"))
        XCTAssertTrue(report.contains("No value recorded"))
        for angle in ["177 degrees", "166 degrees", "155 degrees"] { XCTAssertFalse(report.contains(angle), angle) }
    }
    func testCountAndHoldReportsUseCountedResultsRatherThanAnglePeaks() throws {
        for exercise in [Exercise.sitToStand, .balance] {
            var result = AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil)
            if exercise == .sitToStand { result.repetitions = 7 }
            else { result.holdSeconds = 8; result.liftedFoot = .left }
            let session = Session.recorded(exercise: exercise, side: .right, results: [result])
            XCTAssertEqual(session.countedAttemptCount, 1)
            XCTAssertEqual(session.acceptedTrials, 1)
            XCTAssertTrue(try text(ReportBuilder.data(for: session, in: [session])).contains("1 of 1 attempts counted"))
            session.reportDetailsData = Data()
            session.captureVersion = 3
            session.acceptedTrials = 0
            XCTAssertEqual(session.countedAttemptCount, 1)
        }
    }
    func testMissingValueAfterBaselineIsNotLabeledAsPartOfBaseline() throws {
        let history = (1...3).map { record($0) }
        let missing = Session(date: Date(timeIntervalSince1970: 4 * 86400), side: .right,
                              attemptCount: 1, countedPeaks: [], notCountedReasons: ["tilt"])
        let report = try text(ReportBuilder.data(for: missing, in: history + [missing]))
        XCTAssertTrue(report.contains("No difference is shown because this record has no value."))
        XCTAssertFalse(report.contains("This record is part of the starting point."))
    }
    func testManualReportDoesNotClaimCameraChecks() throws {
        var result = AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil)
        result.repetitions = 8
        let session = Session.recorded(exercise: .manualCount, side: .right, results: [result])
        let report = try text(ReportBuilder.data(for: session, in: [session]))
        XCTAssertTrue(report.contains("8 repetitions"))
        XCTAssertTrue(report.contains("Camera checks do not apply to manual entries."))
        XCTAssertFalse(report.contains("A counted attempt met the recording rules."))
        XCTAssertFalse(report.contains("Attempt 1:"))
    }
    func testReadableSyntheticExampleExport() throws {
        let template = CustomCheckIn(name: "Synthetic example, not a real record",
                                     instructions: "Synthetic layout example. No person was recorded.", exercise: .armRaise)
        let start = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-01T15:00:00Z"))
        let history = (0..<8).map { index in
            let session = record(index + 1, custom: template)
            session.date = start.addingTimeInterval(Double(index) * 86400)
            return session
        }
        let selected = try XCTUnwrap(history.last)
        let plan = CarePlan(routines: [.armRaise], weeklyGoal: 3)
        let bytes = ReportBuilder.data(for: selected, in: history, plan: plan)
        let document = try XCTUnwrap(PDFDocument(data: bytes))
        XCTAssertGreaterThanOrEqual(document.pageCount, 4)
        let attachment = XCTAttachment(data: bytes, uniformTypeIdentifier: "com.adobe.pdf")
        attachment.name = "Bearing-example-report-synthetic"
        attachment.lifetime = .keepAlways; add(attachment)
        for index in 0..<document.pageCount {
            let page = try XCTUnwrap(document.page(at: index))
            let preview = XCTAttachment(image: page.thumbnail(of: CGSize(width: 918, height: 1188), for: .mediaBox))
            preview.name = "Example-page-\(index + 1)"
            preview.lifetime = .keepAlways; add(preview)
        }
    }
    func testEveryPageHasDisclaimerAndTextStaysInsideBounds() throws {
        for language in [AppLanguage.english, .spanish] {
            Loc.preference = language
            let template = CustomCheckIn(name: String(repeating: "A", count: 60),
                                        instructions: String(repeating: "Saved instructions. ", count: 25), exercise: .armRaise)
            let session = record(40, custom: template)
            let plan = CarePlan(routines: [.armRaise], weeklyGoal: 4)
            let history = (1...39).map { record($0, custom: template) } + [session]
            let bytes = ReportBuilder.data(for: session, in: history, plan: plan)
            let document = try XCTUnwrap(PDFDocument(data: bytes))
            XCTAssertGreaterThanOrEqual(document.pageCount, 4)
            let all = try text(bytes)
            XCTAssertTrue(all.contains(Loc.f("Showing %lld of %lld matching records, most recent first.", 24, 40)))
            for index in 0..<document.pageCount {
                let page = try XCTUnwrap(document.page(at: index))
                let pageText = (page.string ?? "").split(whereSeparator: \.isWhitespace).joined(separator: " ")
                XCTAssertTrue(pageText.contains(Strings.disclaimer), "Missing footer on page \(index + 1)")
                for line in page.selection(for: page.bounds(for: .mediaBox))?.selectionsByLine() ?? [] {
                    let bounds = line.bounds(for: page)
                    XCTAssertGreaterThanOrEqual(bounds.minY, 24)
                    XCTAssertLessThanOrEqual(bounds.maxY, 750)
                }
                let attachment = XCTAttachment(image: page.thumbnail(of: CGSize(width: 918, height: 1188), for: .mediaBox))
                attachment.name = "Detailed-\(language.rawValue)-page-\(index + 1)"
                attachment.lifetime = .keepAlways; add(attachment)
            }

        }
    }
}
