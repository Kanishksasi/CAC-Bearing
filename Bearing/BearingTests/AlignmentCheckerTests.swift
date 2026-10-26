import XCTest
@testable import Bearing

final class AlignmentCheckerTests: XCTestCase {
    private func status(tilt: Double? = 1, modify: (Int, inout PoseFrame) -> Void = { _, _ in }) -> AlignmentStatus {
        var checker = AlignmentChecker()
        var status = AlignmentStatus.empty
        for index in 0..<46 {
            var frame = TestFrames.frame(t: Double(index) / 30)
            modify(index, &frame)
            status = checker.evaluate(frame: frame, tiltDegrees: tilt)
        }
        return status
    }
    func testStableCenteredUprightBodyReady() { XCTAssertTrue(status().isReady) }
    func testFullSecondRequired() {
        var checker = AlignmentChecker()
        var result = AlignmentStatus.empty
        for index in 0..<30 { result = checker.evaluate(frame: TestFrames.frame(t: Double(index) / 30), tiltDegrees: 1) }
        XCTAssertFalse(result.stable)
        XCTAssertTrue(checker.evaluate(frame: TestFrames.frame(t: 1), tiltDegrees: 1).stable)
    }
    func testTiltAndMissingTiltBlockStart() {
        XCTAssertFalse(status(tilt: 8).isReady)
        XCTAssertFalse(status(tilt: nil).isReady)
        XCTAssertFalse(status(tilt: -.infinity).isReady)
    }
    func testSecondPersonBlocksStart() {
        XCTAssertFalse(status { _, frame in frame.multiplePeople = true }.isReady)
    }
    func testMissingOrHeldJointsBlockStart() {
        XCTAssertFalse(status { _, frame in frame.joints[.rightElbow] = nil }.isReady)
        XCTAssertFalse(status { _, frame in frame.joints[.rightElbow]?.isImputed = true }.isReady)
    }
    func testShoulderAsymmetryDoesNotBlockStart() {
        XCTAssertTrue(status { _, frame in frame.joints[.leftShoulder]?.position.y += 25 }.isReady)
    }
    func testVerticalAndHorizontalMotionBlockStability() {
        XCTAssertFalse(status { index, frame in
            for name in JointName.allCases { frame.joints[name]?.position.y += index.isMultiple(of: 2) ? 0 : 60 }
        }.stable)
        XCTAssertFalse(status { index, frame in
            for name in JointName.allCases { frame.joints[name]?.position.x += index.isMultiple(of: 2) ? 0 : 60 }
        }.stable)
    }
    func testInterruptionResetsHistory() {
        var checker = AlignmentChecker()
        for index in 0..<36 { _ = checker.evaluate(frame: TestFrames.frame(t: Double(index) / 30), tiltDegrees: 1) }
        _ = checker.evaluate(frame: TestFrames.frame(t: 1.2), tiltDegrees: 8)
        XCTAssertFalse(checker.evaluate(frame: TestFrames.frame(t: 1.23), tiltDegrees: 1).stable)
    }
    func testMissingCameraFramesResetHistory() {
        var checker = AlignmentChecker()
        for index in 0..<36 { _ = checker.evaluate(frame: TestFrames.frame(t: Double(index) / 30), tiltDegrees: 1) }
        XCTAssertFalse(checker.evaluate(frame: TestFrames.frame(t: 2), tiltDegrees: 1).stable)
    }
    func testOutOfFrameAndDistanceBlockStart() {
        XCTAssertEqual(status { _, frame in frame.joints[.rightElbow]?.position.x = 0 }.framing, .outOfFrame)
        XCTAssertEqual(status { _, frame in
            frame.joints[.leftHip]?.position.y = 800
            frame.joints[.rightHip]?.position.y = 800
        }.framing, .tooFar)
        XCTAssertEqual(status { _, frame in
            frame.joints[.leftHip]?.position.y = 300
            frame.joints[.rightHip]?.position.y = 300
        }.framing, .tooClose)
    }
}
