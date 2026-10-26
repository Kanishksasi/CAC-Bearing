import XCTest
import CoreGraphics
@testable import Bearing

final class AdditionalRoutineTests: XCTestCase {
    static func body(_ t: Double, hipY: Double = 600, lift: Double = 0, sway: Double = 0) -> PoseFrame {
        var f = TestFrames.frame(t: t)
        func put(_ j: JointName, _ x: Double, _ y: Double) {
            f.joints[j] = JointPoint(position: CGPoint(x: x, y: y), confidence: 0.99, isImputed: false)
        }
        put(.leftShoulder, 260, hipY + 300); put(.rightShoulder, 460, hipY + 300)
        put(.leftHip, 260 + sway, hipY); put(.rightHip, 460 + sway, hipY)
        put(.leftKnee, 260, 380); put(.rightKnee, 460, 380)
        put(.leftAnkle, 260, 120 + max(0, lift)); put(.rightAnkle, 460, 120 + max(0, -lift))
        return f
    }
    private func standRun(_ engine: SitToStandEngine, scale: Double = 1,
                          modify: (Double, inout PoseFrame) -> Void = { _, _ in }) {
        for i in 0..<900 {
            let t = Double(i) / 30
            let phase = t.truncatingRemainder(dividingBy: 4)
            let initial = Self.body(t, hipY: phase >= 1 && phase < 2.5 ? 780 : 600)
            var f = PoseFrame(timestamp: t, size: CGSize(width: initial.size.width * scale, height: initial.size.height * scale), joints: initial.joints)
            for j in Array(f.joints.keys) { f.joints[j]!.position.x *= scale; f.joints[j]!.position.y *= scale }
            modify(t, &f); engine.ingest(f, tiltDegrees: 0)
        }
    }
    func testSitToStandCountsHysteresisCyclesAndIsScaleIndependent() {
        for scale in [1.0, 2.0] {
            let engine = SitToStandEngine(startTime: 0); standRun(engine, scale: scale)
            let result = engine.finish(endTime: 30)
            XCTAssertTrue(result.counted); XCTAssertEqual(result.repetitions, 8)
        }
    }
    func testSitToStandRequiresSeatedCalibrationAndFullDuration() {
        let engine = SitToStandEngine(startTime: 0)
        for i in 0..<12 { engine.ingest(Self.body(Double(i) / 30), tiltDegrees: 0) }
        XCTAssertFalse(engine.finish(endTime: 0.4).counted)
    }
    func testSitToStandRejectsHeldHipAndGapAndTiltBetweenFrames() {
        let held = SitToStandEngine(startTime: 0)
        standRun(held) { _, f in f.joints[.leftHip]!.isImputed = true }
        XCTAssertEqual(held.finish(endTime: 30).reason, .lowConfidence)
        let gap = SitToStandEngine(startTime: 0)
        for i in 0..<900 where !(300...330).contains(i) {
            gap.ingest(Self.body(Double(i) / 30), tiltDegrees: 0)
        }
        XCTAssertEqual(gap.finish(endTime: 30).reason, .lowConfidence)
        let tilt = SitToStandEngine(startTime: 0); standRun(tilt); tilt.observeTilt(8)
        XCTAssertEqual(tilt.finish(endTime: 30).reason, .tilt)
    }
    func testSitToStandDoesNotCountWobbleWithoutReturningSeated() {
        let engine = SitToStandEngine(startTime: 0)
        for i in 0..<900 {
            let t = Double(i) / 30
            let y = t < 1 ? 600 : (i.isMultiple(of: 2) ? 780 : 735)
            engine.ingest(Self.body(t, hipY: Double(y)), tiltDegrees: 0)
        }
        XCTAssertEqual(engine.finish(endTime: 30).repetitions, 1)
    }
    func testBalanceCapsAtTenSecondsAndComputesNormalizedSway() throws {
        let engine = BalanceEngine(startTime: 0)
        for i in 0..<390 {
            let t = Double(i) / 30
            engine.ingest(Self.body(t, lift: t < 0.5 ? 0 : 60, sway: i.isMultiple(of: 2) ? 10 : -10), tiltDegrees: 0)
        }
        let result = engine.finish(endTime: 13)
        XCTAssertTrue(result.counted); XCTAssertEqual(result.liftedFoot, .left)
        XCTAssertEqual(try XCTUnwrap(result.holdSeconds), 10, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(result.swayRatio), 0.05, accuracy: 0.001)
    }
    func testBalanceRightFootAndContactEndTheFirstHold() throws {
        let engine = BalanceEngine(startTime: 0)
        for i in 0..<150 {
            let t = Double(i) / 30
            engine.ingest(Self.body(t, lift: t >= 0.5 && t < 3 ? -60 : 0), tiltDegrees: 0)
        }
        let result = engine.finish(endTime: 5)
        XCTAssertEqual(result.liftedFoot, .right)
        XCTAssertEqual(try XCTUnwrap(result.holdSeconds), 2.5, accuracy: 0.04)
    }
    func testBalanceNoLiftAndChangingFeetHaveExplicitReasons() {
        let noLift = BalanceEngine(startTime: 0), changed = BalanceEngine(startTime: 0)
        for i in 0..<150 {
            let t = Double(i) / 30
            noLift.ingest(Self.body(t), tiltDegrees: 0)
            changed.ingest(Self.body(t, lift: t < 2 ? 60 : -60), tiltDegrees: 0)
        }
        XCTAssertEqual(noLift.finish(endTime: 5).reason, .noLift)
        XCTAssertEqual(changed.finish(endTime: 5).reason, .footChanged)
    }
    func testBalanceMissingAnkleOrMotionCannotCount() {
        let missing = BalanceEngine(startTime: 0), motion = BalanceEngine(startTime: 0)
        for i in 0..<150 {
            let t = Double(i) / 30
            var f = Self.body(t, lift: 60); f.joints[.leftAnkle] = nil
            missing.ingest(f, tiltDegrees: 0)
            motion.ingest(Self.body(t, lift: 60), tiltDegrees: nil)
        }
        XCTAssertFalse(missing.finish(endTime: 5).counted)
        XCTAssertEqual(motion.finish(endTime: 5).reason, .motionUnavailable)
    }
    func testKneeBendReportsFlexionForBothAnatomicalSides() throws {
        for side in Side.allCases {
            let engine = JointAngleEngine(exercise: .kneeBend, side: side, startTime: 0)
            for i in 0..<180 {
                let t = Double(i) / 30
                var f = Self.body(t)
                let a = t < 2 ? 5 + 35 * t : (t < 3 ? 75 : max(5, 75 - 35 * (t - 3)))
                let knee = f.joints[.knee(side)]!.position
                let r = a * .pi / 180
                f.joints[.ankle(side)]!.position = CGPoint(x: knee.x + (side == .left ? -1 : 1) * 200 * sin(r), y: knee.y - 200 * cos(r))
                engine.ingest(f, tiltDegrees: 0)
            }
            let result = engine.finish(endTime: 6)
            XCTAssertTrue(result.counted)
            XCTAssertEqual(try XCTUnwrap(result.peakAngle), 75, accuracy: 0.001)
        }
    }
    func testSideReachDoesNotRequireOccludedFarSide() throws {
        for side in Side.allCases {
            let engine = JointAngleEngine(exercise: .shoulderReach, side: side, startTime: 0)
            for i in 0..<180 {
                let t = Double(i) / 30
                var f = TestFrames.frame(t: t, angle: TestFrames.angle(at: t), side: side)
                f.joints = f.joints.filter { Exercise.shoulderReach.requiredJoints(side: side).contains($0.key) }
                engine.ingest(f, tiltDegrees: 0)
            }
            XCTAssertEqual(try XCTUnwrap(engine.finish(endTime: 6).peakAngle), 120, accuracy: 0.001)
            XCTAssertTrue(engine.finish(endTime: 6).counted)
        }
    }
    func testAddedAnklesHaveHigherConfidenceAndDisplayIsMirroredOnlyWhenRequested() {
        XCTAssertEqual(JointName.leftAnkle.confidenceTier, 0.5)
        let p = CGPoint(x: 100, y: 200), image = CGSize(width: 720, height: 1280)
        XCTAssertEqual(Geometry.displayPoint(p, image: image, view: image, mirrored: false), CGPoint(x: 100, y: 1080))
        XCTAssertEqual(Geometry.displayPoint(p, image: image, view: image), CGPoint(x: 620, y: 1080))
    }
    func testSideViewAndFullBodyAlignmentUseTheirOwnRequiredJoints() {
        var sideChecker = AlignmentChecker(), balanceChecker = AlignmentChecker()
        var sideReady = false, balanceReady = false
        for i in 0...36 {
            var side = Self.body(Double(i) / 30)
            side.joints = side.joints.filter { Exercise.shoulderReach.requiredJoints(side: .right).contains($0.key) }
            sideReady = sideChecker.evaluate(frame: side, tiltDegrees: 0, exercise: .shoulderReach).isReady
            balanceReady = balanceChecker.evaluate(frame: Self.body(Double(i) / 30), tiltDegrees: 0, exercise: .balance).isReady
        }
        XCTAssertTrue(sideReady); XCTAssertTrue(balanceReady)
    }
}
