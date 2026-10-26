import XCTest
import AVFoundation
@testable import Bearing

final class HandsFreeAndSpeechTests: XCTestCase {
    func testWaitsUntilArmedAndContinuouslyReady() {
        var gate = HandsFreeStart()
        XCTAssertFalse(gate.update(ready: true, now: 0))
        gate.arm()
        XCTAssertFalse(gate.update(ready: false, now: 1))
        XCTAssertFalse(gate.update(ready: true, now: 10))
        XCTAssertFalse(gate.update(ready: true, now: 11.9))
        XCTAssertTrue(gate.update(ready: true, now: 12))
        XCTAssertFalse(gate.isArmed)
        XCTAssertFalse(gate.update(ready: true, now: 15))
    }
    func testLostPositionRestartsWaitAndCancelPreventsRecording() {
        var gate = HandsFreeStart()
        gate.arm()
        XCTAssertFalse(gate.update(ready: true, now: 0))
        XCTAssertFalse(gate.update(ready: false, now: 1.9))
        XCTAssertFalse(gate.update(ready: true, now: 2))
        XCTAssertFalse(gate.update(ready: true, now: 3))
        gate.cancel()
        XCTAssertFalse(gate.update(ready: true, now: 8))
        gate.arm()
        XCTAssertFalse(gate.update(ready: true, now: 9))
        XCTAssertTrue(gate.update(ready: true, now: 11))
    }
    func testSyntheticPoseAndTiltMustRecoverBeforeAutomaticStart() {
        var checker = AlignmentChecker()
        var gate = HandsFreeStart()
        gate.arm()
        var startedAt: Double?
        for index in 0..<210 {
            let time = Double(index) / 30
            let status = checker.evaluate(frame: TestFrames.frame(t: time), tiltDegrees: index == 75 ? 8 : 1)
            if gate.update(ready: status.isReady, now: time) { startedAt = time }
        }
        XCTAssertNotNil(startedAt)
        XCTAssertGreaterThanOrEqual(startedAt ?? 0, 5.5)
        XCTAssertLessThan(startedAt ?? 100, 5.6)
    }
    func testSpeechSpeedsAreOrderedAndWithinSupportedRange() {
        XCTAssertLessThan(SpeechSpeed.slower.rate, SpeechSpeed.normal.rate)
        XCTAssertLessThan(SpeechSpeed.normal.rate, SpeechSpeed.faster.rate)
        for speed in SpeechSpeed.allCases {
            XCTAssertGreaterThanOrEqual(speed.rate, AVSpeechUtteranceMinimumSpeechRate)
            XCTAssertLessThanOrEqual(speed.rate, AVSpeechUtteranceMaximumSpeechRate)
        }
    }
}
