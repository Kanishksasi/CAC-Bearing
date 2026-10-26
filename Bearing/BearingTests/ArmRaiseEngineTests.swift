import XCTest
@testable import Bearing

final class ArmRaiseEngineTests: XCTestCase {
    func testFullRaiseBothAnatomicalSides() {
        for side in Side.allCases {
            let engine = ArmRaiseEngine(side: side)
            TestFrames.run(engine)
            XCTAssertTrue(engine.finish().counted)
            XCTAssertEqual(engine.finish().peakAngle ?? 0, 120, accuracy: 0.01)
        }
    }
    func testTiltAtAnyPointRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, tilt: { $0 > 5.5 ? 8 : 1 })
        XCTAssertEqual(engine.finish().reason, .tilt)
    }
    func testMissingTiltRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, tilt: { $0 > 5.5 ? nil : 1 })
        XCTAssertEqual(engine.finish().reason, .motionUnavailable)
    }
    func testInvalidTiltRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, tilt: { _ in .nan })
        XCTAssertEqual(engine.finish().reason, .motionUnavailable)
    }
    func testArmMustReturnLow() {
        let engine = ArmRaiseEngine(side: .right)
        for i in 0..<180 {
            let time = Double(i) / 30
            engine.ingest(TestFrames.frame(t: time, angle: min(120, 10 + 55 * time)), tiltDegrees: 1)
        }
        XCTAssertEqual(engine.finish().reason, .noClearRaise)
    }
    func testArmMustStartLow() {
        let engine = ArmRaiseEngine(side: .right)
        for i in 0..<180 {
            let time = Double(i) / 30
            engine.ingest(TestFrames.frame(t: time, angle: max(10, 120 - time * 25)), tiltDegrees: 1)
        }
        XCTAssertEqual(engine.finish().reason, .noClearRaise)
    }
    func testSmallMovementNotCounted() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { _, frame in frame = TestFrames.frame(t: frame.timestamp, angle: 20) })
        XCTAssertEqual(engine.finish().reason, .noClearRaise)
    }
    func testHiddenPeakNotCounted() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { time, frame in if time > 1.9 && time < 3.1 { frame.joints[.rightElbow] = nil } })
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testCameraStallCannotDisappearFromCoverage() {
        let engine = ArmRaiseEngine(side: .right)
        for i in 0..<180 {
            let time = Double(i) / 30
            if time > 2 && time < 2.6 { continue }
            engine.ingest(TestFrames.frame(t: time, angle: TestFrames.angle(at: time)), tiltDegrees: 1)
        }
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testStallAfterCompleteMovementStillRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right, startTime: 0)
        TestFrames.run(engine)
        XCTAssertEqual(engine.finish(endTime: 6.5).reason, .lowConfidence)
    }
    func testStallBeforeMovementRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right, startTime: -1)
        TestFrames.run(engine)
        XCTAssertEqual(engine.finish(endTime: 6).reason, .lowConfidence)
    }
    func testSlowSampleRateNotCounted() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, hz: 10)
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testOppositeElbowNotRequiredDuringAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { _, frame in frame.joints[.leftElbow] = nil })
        XCTAssertTrue(engine.finish().counted)
    }
    func testOppositeHipIsRequired() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { _, frame in frame.joints[.leftHip] = nil })
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testHeldTorsoCannotCountAsFresh() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { _, frame in frame.joints[.leftShoulder]?.isImputed = true })
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testConfidenceCheckedWithoutFilter() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { _, frame in frame.joints[.rightElbow]?.confidence = 0.49 })
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testRequiredJointAtEdgeNotCounted() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { time, frame in if time > 2 && time < 2.5 { frame.joints[.rightElbow]?.position.x = 5 } })
        XCTAssertEqual(engine.finish().reason, .outOfFrame)
    }
    func testUnneededOppositeElbowAtEdgeDoesNotReject() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { _, frame in frame.joints[.leftElbow]?.position.x = 0 })
        XCTAssertTrue(engine.finish().counted)
    }
    func testTrunkLeanNearPeakNotCounted() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { _, frame in
            frame.joints[.leftShoulder]?.position.x -= 60
            frame.joints[.rightShoulder]?.position.x -= 60
            frame.joints[.rightElbow]?.position.x -= 60
        })
        XCTAssertEqual(engine.finish().reason, .trunkLean)
    }
    func testSecondPersonEvenBrieflyRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { time, frame in frame.multiplePeople = time > 1 && time < 1.04 })
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testDuplicateTimestampsRejectAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { time, frame in if time > 2 && time < 2.04 { frame = TestFrames.frame(t: 1) } })
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
    func testMedianOfTopFiveRejectsSingleFrameSpike() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine, modify: { time, frame in if time == 2 { frame = TestFrames.frame(t: time, angle: 170) } })
        XCTAssertEqual(engine.finish().peakAngle ?? 0, 120, accuracy: 0.01)
    }
    func testSmoothedPipelineProducesFullRaise() {
        let engine = ArmRaiseEngine(side: .right)
        var filter = SignalFilter()
        for i in 0..<180 {
            let time = Double(i) / 30
            engine.ingest(filter.apply(TestFrames.frame(t: time, angle: TestFrames.angle(at: time))), tiltDegrees: 1)
        }
        XCTAssertTrue(engine.finish().counted)
        XCTAssertEqual(engine.finish().peakAngle ?? 0, 120, accuracy: 0.1)
    }
    func testTiltBetweenCameraFramesStillRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine)
        engine.observeTilt(8)
        engine.observeTilt(1)
        XCTAssertEqual(engine.finish().reason, .tilt)
    }
    func testMotionStoppingAfterLastFrameRejectsAttempt() {
        let engine = ArmRaiseEngine(side: .right)
        TestFrames.run(engine)
        engine.observeTilt(nil)
        XCTAssertEqual(engine.finish().reason, .motionUnavailable)
    }
    func testTotalCameraStallWithWorkingMotionReportsTrackingReason() {
        let engine = ArmRaiseEngine(side: .right)
        engine.observeTilt(1)
        XCTAssertEqual(engine.finish().reason, .lowConfidence)
    }
}
