import XCTest

final class BearingUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launch(spanish: Bool = false, largestText: Bool = false, sampleSession: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestFreshStore", "-UITestNoCamera", "-UITestSilent", "-AppleLanguages", spanish ? "(es)" : "(en)"]
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        if sampleSession { app.launchArguments.append("-UITestSampleSession") }
        app.launch()
        let consent = app.buttons[spanish ? "Entiendo" : "I understand"]
        XCTAssertTrue(consent.waitForExistence(timeout: 10))
        reveal(consent, in: app)
        consent.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: consent)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        return app
    }

    @MainActor
    private func previewReport(in app: XCUIApplication) {
        app.buttons["Create PDF summary"].tap()
        XCTAssertTrue(app.buttons["Preview PDF"].waitForExistence(timeout: 5))
        for label in ["Include matching history", "Include plan details", "Include saved custom instructions"] {
            let option = app.switches[label]
            let form = app.collectionViews.firstMatch
            for _ in 0..<12 {
                if option.exists && option.isHittable { break }
                if form.exists { form.swipeUp() } else { app.swipeUp() }
            }
            XCTAssertTrue(option.exists)
            XCTAssertEqual(option.value as? String, "0")
        }
        app.buttons["Preview PDF"].tap()
        let share = app.buttons["Share PDF"]
        XCTAssertTrue(share.waitForExistence(timeout: 5)); XCTAssertFalse(share.isEnabled)
        let consent = app.switches["ReportConsent"]
        XCTAssertTrue(consent.exists)
        if consent.switches.firstMatch.exists { consent.switches.firstMatch.tap() } else { consent.tap() }
        capture("Report-Consent-TestFixture", app: app)
        XCTAssertEqual(consent.value as? String, "1")
        XCTAssertTrue(share.isEnabled)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Create PDF summary"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func reveal(_ item: XCUIElement, in app: XCUIApplication) {
        var visibleBottom = app.windows.firstMatch.frame.maxY - 20
        for name in ["Continue", "HandsFreeStart", "Create PDF summary", "Share PDF", "Preview PDF"] {
            let fixed = app.buttons[name]
            if fixed.exists && fixed.label != item.label && fixed.isHittable {
                visibleBottom = min(visibleBottom, fixed.frame.minY - 12)
            }
        }
        for _ in 0..<16 {
            if item.isHittable && item.frame.maxY <= visibleBottom { return }
            app.swipeUp()
        }
    }

    @MainActor
    func testHomeOffersRoutinesCustomPlanHistoryPrivacy() {
        let app = launch()
        XCTAssertTrue(app.buttons["Start arm raise"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["History"].exists)
        XCTAssertTrue(app.buttons["Privacy and data"].exists)
        for title in ["All routines", "Custom check-ins", "My plan"] { XCTAssertTrue(app.buttons[title].exists) }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home-English"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testHandsFreeCanWaitAndCancelWithoutAlignment() {
        let app = launch()
        app.buttons["Start arm raise"].tap()
        reveal(app.buttons["Continue"], in: app); app.buttons["Continue"].tap()
        let arm = app.buttons["HandsFreeStart"]
        XCTAssertTrue(arm.waitForExistence(timeout: 5))
        XCTAssertTrue(arm.isEnabled)
        XCTAssertFalse(app.buttons["StartAttempt"].isEnabled)
        arm.tap()
        XCTAssertTrue(app.staticTexts["Waiting for your position"].waitForExistence(timeout: 5))
        capture("Hands-Free-Waiting", app: app)
        let stop = app.buttons["Stop without saving"]
        reveal(stop, in: app); stop.tap()
        XCTAssertTrue(app.buttons["HandsFreeStart"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["StartAttempt"].isEnabled)
    }

    @MainActor
    func testVoiceSpeedCanChangeAndResultExplainsSummary() {
        let app = launch(sampleSession: true)
        let picker = app.buttons["VoiceSpeed"]
        reveal(picker, in: app); picker.tap()
        app.buttons["Slower"].tap()
        XCTAssertTrue(app.buttons["Try voice"].exists)
        reveal(app.buttons["History"], in: app); app.buttons["History"].tap()
        app.buttons.matching(identifier: "SavedSession").firstMatch.tap()
        let meaning = app.staticTexts["What this number means"]
        reveal(meaning, in: app); XCTAssertTrue(meaning.exists)
        capture("Result-Meaning-TestFixture", app: app)
    }

    @MainActor
    func testEmptyHistory() {
        let app = launch()
        reveal(app.buttons["History"], in: app)
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["No sessions yet."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteRequiresConfirmationAndReportsCompletion() {
        let app = launch()
        reveal(app.buttons["Privacy and data"], in: app)
        app.buttons["Privacy and data"].tap()
        let delete = app.buttons["Delete all my data"]
        reveal(delete, in: app)
        delete.tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        delete.tap()
        app.buttons["Delete all"].tap()
        XCTAssertTrue(app.staticTexts["All sessions, settings, and temporary PDFs were deleted."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCameraGateBlocksStartAndRepeatRemainsReachable() {
        let app = launch()
        app.buttons["Start arm raise"].tap()
        capture("Setup-English", app: app)
        let next = app.buttons["Continue"]
        reveal(next, in: app)
        next.tap()
        let start = app.buttons["StartAttempt"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        reveal(start, in: app)
        XCTAssertFalse(start.isEnabled)
        reveal(app.buttons["Repeat instructions"], in: app)
        XCTAssertTrue(app.buttons["Repeat instructions"].isHittable)
        app.buttons["Repeat instructions"].tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Alignment-Blocked"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSpanishHomeAndSetup() {
        let app = launch(spanish: true)
        XCTAssertTrue(app.buttons["Empezar movimiento del brazo"].waitForExistence(timeout: 5))
        app.buttons["Empezar movimiento del brazo"].tap()
        XCTAssertTrue(app.staticTexts["Elija un brazo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Brazo derecho"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Setup-Spanish"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLanguagePickerUpdatesVisibleText() {
        let app = launch()
        let language = app.buttons["LanguagePicker"]
        reveal(language, in: app)
        language.tap()
        app.buttons["Español"].tap()
        let start = app.buttons["Empezar movimiento del brazo"]
        app.swipeDown()
        XCTAssertTrue(start.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLargestTextKeepsSetupAndRepeatReachable() {
        let app = launch(largestText: true)
        let start = app.buttons["Start arm raise"]
        reveal(start, in: app)
        start.tap()
        let next = app.buttons["Continue"]
        reveal(next, in: app)
        XCTAssertTrue(next.isHittable)
        next.tap()
        XCTAssertTrue(app.buttons["HandsFreeStart"].waitForExistence(timeout: 5))
        let setupGone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: next)
        XCTAssertEqual(XCTWaiter.wait(for: [setupGone], timeout: 5), .completed)
        let repeatButton = app.buttons["Repeat instructions"]
        reveal(repeatButton, in: app)
        XCTAssertTrue(repeatButton.isHittable)
        let startAttempt = app.buttons["StartAttempt"]
        reveal(startAttempt, in: app)
        XCTAssertTrue(startAttempt.isHittable)
        XCTAssertFalse(startAttempt.isEnabled)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Largest-Text-Alignment"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testHomeAccessibilityAudit() throws {
        let app = launch()
        // The iOS 18.6 contrast audit misreads offscreen rows. DesignContrastTests checks the color pairs.
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .textClipped, .dynamicType])
    }
    @MainActor
    private func capture(_ name: String, app: XCUIApplication) {
        // Wait for the navigation animation, not just the element.
        Thread.sleep(forTimeInterval: 0.5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSavedResultExportsAndReturnsHome() throws {
        let app = launch(sampleSession: true)
        reveal(app.buttons["History"], in: app)
        app.buttons["History"].tap()
        let saved = app.buttons.matching(identifier: "SavedSession").firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        XCTAssertTrue(app.staticTexts["Arm angle summary"].waitForExistence(timeout: 5))
        capture("Result-English-TestFixture", app: app)
        try auditVisibleResult(app)
        reveal(app.buttons["Done"], in: app)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .textClipped])
        let export = app.buttons["Create PDF summary"]
        reveal(export, in: app)
        previewReport(in: app)
        reveal(app.buttons["Done"], in: app)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Start arm raise"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Bearing"].exists)
    }

    @MainActor
    func testSavedResultOffersOppositeArm() {
        let app = launch(sampleSession: true)
        reveal(app.buttons["History"], in: app)
        app.buttons["History"].tap()
        let saved = app.buttons.matching(identifier: "SavedSession").firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        let other = app.buttons["Record the other arm"]
        reveal(other, in: app)
        other.tap()
        XCTAssertTrue(app.buttons["Left arm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Left arm"].isSelected)
    }

    @MainActor
    func testLargestResultKeepsExportAndDoneReachable() {
        let app = launch(largestText: true, sampleSession: true)
        reveal(app.buttons["History"], in: app)
        reveal(app.buttons["History"], in: app)
        app.buttons["History"].tap()
        let saved = app.buttons.matching(identifier: "SavedSession").firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        let export = app.buttons["Create PDF summary"]
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        XCTAssertTrue(export.isHittable)
        capture("Result-Largest-Text-TestFixture", app: app)
        previewReport(in: app)
        reveal(app.buttons["Done"], in: app)
        XCTAssertGreaterThan(app.buttons["Done"].frame.height, 56)
        capture("Result-Largest-Actions-TestFixture", app: app)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Bearing"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func auditVisibleResult(_ app: XCUIApplication) throws {
        // The iOS 18.6 contrast audit misreads offscreen rows. DesignContrastTests checks the color pairs.
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .textClipped, .dynamicType])
    }

    @MainActor
    func testAllFiveRoutinesAreAvailable() {
        let app = launch()
        reveal(app.buttons["All routines"], in: app); app.buttons["All routines"].tap()
        XCTAssertTrue(app.staticTexts["Choose a routine"].waitForExistence(timeout: 5))
        for title in ["Arm raise", "Sit to stand", "One-leg balance", "Knee bend", "Shoulder reach"] {
            XCTAssertTrue(app.buttons[title].exists)
        }
        capture("Routine-Library", app: app)
    }

    @MainActor
    func testSitToStandRequiresSupportAcknowledgement() {
        let app = launch()
        reveal(app.buttons["All routines"], in: app); app.buttons["All routines"].tap()
        app.buttons["Sit to stand"].tap()
        let next = app.buttons["Continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 5)); XCTAssertFalse(next.isEnabled)
        let support = app.switches["Support and someone are within reach"]
        reveal(support, in: app); support.tap()
        XCTAssertTrue(next.isEnabled); next.tap()
        XCTAssertTrue(app.buttons["StartAttempt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["StartAttempt"].isEnabled)
    }

    @MainActor
    private func createCustom(in app: XCUIApplication, name: String, mode: String) {
        reveal(app.buttons["Custom check-ins"], in: app); app.buttons["Custom check-ins"].tap()
        app.buttons["Create a check-in"].tap()
        let field = app.textFields["CustomName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText(name)
        app.buttons["CustomRecorder"].tap(); app.buttons[mode].tap()
        let save = app.buttons["SaveCustom"]
        reveal(save, in: app); save.tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCustomManualCountSavesWithItsSourceAndExports() {
        let app = launch()
        createCustom(in: app, name: "My daily count", mode: "Manual count")
        app.buttons["OpenCustom"].tap()
        XCTAssertTrue(app.staticTexts["Manual entry"].firstMatch.waitForExistence(timeout: 5))
        let save = app.buttons["Save and see results"]
        reveal(save, in: app); save.tap()
        XCTAssertTrue(app.staticTexts["Your recorded entry"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0 repetitions"].exists)
        previewReport(in: app)
        capture("Manual-Count-Result", app: app)
    }

    @MainActor
    func testCustomTimerCanPauseAndSaveWithoutCamera() {
        let app = launch()
        createCustom(in: app, name: "My timed check-in", mode: "Manual timer")
        app.buttons["OpenCustom"].tap()
        let start = app.buttons["Start timer"]
        reveal(start, in: app); start.tap()
        XCTAssertTrue(app.buttons["Pause timer"].waitForExistence(timeout: 5))
        let elapsed = app.staticTexts["ManualElapsed"]
        let progressed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0.0 seconds"), object: elapsed)
        XCTAssertEqual(XCTWaiter.wait(for: [progressed], timeout: 5), .completed)
        app.buttons["Pause timer"].tap()
        let save = app.buttons["Save and see results"]
        reveal(save, in: app); XCTAssertTrue(save.isEnabled); save.tap()
        XCTAssertTrue(app.staticTexts["Your recorded entry"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["StartAttempt"].exists)
    }

    @MainActor
    func testCustomCameraTemplateKeepsSupportedSetup() {
        let app = launch()
        createCustom(in: app, name: "My arm routine", mode: "Arm raise")
        app.buttons["OpenCustom"].tap()
        XCTAssertTrue(app.staticTexts["Choose an arm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Right arm"].isSelected)
        capture("Custom-Camera-Setup", app: app)
    }

    @MainActor
    func testLocalPlanSavesWithoutNotificationPromptWhenRemindersAreOff() {
        let app = launch()
        reveal(app.buttons["My plan"], in: app); app.buttons["My plan"].tap()
        let arm = app.switches["Arm raise"]
        XCTAssertTrue(arm.waitForExistence(timeout: 5))
        if arm.switches.firstMatch.exists { arm.switches.firstMatch.tap() } else { arm.tap() }
        XCTAssertEqual(arm.value as? String, "1")
        let save = app.buttons["Save plan"]
        reveal(save, in: app); XCTAssertTrue(save.isEnabled); save.tap()
        let accept = app.buttons["Accept plan changes"]
        XCTAssertTrue(accept.waitForExistence(timeout: 5)); reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.staticTexts["Plan saved."].waitForExistence(timeout: 5))
        app.buttons["OK"].tap()
        capture("Local-Plan", app: app)
        app.navigationBars.buttons.firstMatch.tap()
        reveal(app.buttons["My plan"], in: app); app.buttons["My plan"].tap()
        let savedArm = app.switches["Arm raise"]
        XCTAssertTrue(savedArm.waitForExistence(timeout: 5)); XCTAssertEqual(savedArm.value as? String, "1")
    }

    @MainActor
    func testTodaySkipCanBeUndoneWithoutSavingAResult() {
        let app = launch()
        reveal(app.buttons["My plan"], in: app); app.buttons["My plan"].tap()
        let arm = app.switches["Arm raise"]
        XCTAssertTrue(arm.waitForExistence(timeout: 5))
        if arm.switches.firstMatch.exists { arm.switches.firstMatch.tap() } else { arm.tap() }
        let days = app.buttons["Reminder days"]
        reveal(days, in: app); days.tap()
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US")
        let name = formatter.weekdaySymbols[Calendar.current.component(.weekday, from: .now) - 1]
        let today = app.switches[name]
        reveal(today, in: app)
        if today.value as? String != "1" {
            if today.switches.firstMatch.exists { today.switches.firstMatch.tap() } else { today.tap() }
        }
        let save = app.buttons["Save plan"]
        reveal(save, in: app); save.tap()
        let accept = app.buttons["Accept plan changes"]
        XCTAssertTrue(accept.waitForExistence(timeout: 5)); reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.staticTexts["Plan saved."].waitForExistence(timeout: 5)); app.buttons["OK"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        reveal(app.buttons["Today"], in: app); app.buttons["Today"].tap()
        let skip = app.buttons["Skip today"]
        reveal(skip, in: app); skip.tap()
        XCTAssertTrue(app.staticTexts["Today is skipped."].waitForExistence(timeout: 5))
        let undo = app.buttons["Undo skip"]
        reveal(undo, in: app); undo.tap()
        XCTAssertTrue(app.buttons["Skip today"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Your check-in is recorded for today."].exists)
        capture("Today-Plan-TestFixture", app: app)
    }

}
