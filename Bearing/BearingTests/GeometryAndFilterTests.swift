import XCTest
import CoreGraphics
@testable import Bearing

final class GeometryTests: XCTestCase {
    func testKnownAnglesInPixels() {
        for angle in [0.0, 30, 60, 90, 120, 180] {
            let frame = TestFrames.frame(t: 0, angle: angle)
            let result = Geometry.angleDegrees(vertex: frame.joints[.rightShoulder]!.position,
                                              a: frame.joints[.rightHip]!.position,
                                              b: frame.joints[.rightElbow]!.position)
            XCTAssertEqual(result ?? -1, angle, accuracy: 0.0001)
        }
    }
    func testDegenerateAndNonfiniteVectorsHaveNoAngle() {
        XCTAssertNil(Geometry.angleDegrees(vertex: .zero, a: .zero, b: CGPoint(x: 1, y: 0)))
        XCTAssertNil(Geometry.angleDegrees(vertex: .zero, a: CGPoint(x: Double.nan, y: 0), b: CGPoint(x: 1, y: 0)))
    }
    func testTiltFromGravity() {
        XCTAssertEqual(TiltMonitor.tilt(gx: 0, gy: -1, gz: 0) ?? -1, 0, accuracy: 0.001)
        let radians = 10.0 * .pi / 180
        XCTAssertEqual(TiltMonitor.tilt(gx: 0, gy: -cos(radians), gz: -sin(radians)) ?? -1, 10, accuracy: 0.001)
        XCTAssertNil(TiltMonitor.tilt(gx: 0, gy: 0, gz: 0))
        XCTAssertNil(TiltMonitor.tilt(gx: .nan, gy: -1, gz: 0))
    }
    func testMotionReadingExpiresAfterHalfSecond() {
        XCTAssertEqual(TiltMonitor.fresh(degrees: 1, updatedAt: 10, now: 10.49), 1)
        XCTAssertNil(TiltMonitor.fresh(degrees: 1, updatedAt: 10, now: 10.5))
        XCTAssertNil(TiltMonitor.fresh(degrees: 1, updatedAt: 10, now: 9))
        XCTAssertNil(TiltMonitor.fresh(degrees: nil, updatedAt: 10, now: 10))
    }
    func testLeanFromVerticalInVisionCoordinates() {
        XCTAssertEqual(Geometry.leanFromVerticalDegrees(top: CGPoint(x: 0, y: 300), bottom: .zero), 0)
        XCTAssertEqual(Geometry.leanFromVerticalDegrees(top: CGPoint(x: 300, y: 300), bottom: .zero), 45)
    }
    func testMedian() {
        XCTAssertNil(Geometry.median([]))
        XCTAssertEqual(Geometry.median([9, 1, 3]), 3)
        XCTAssertEqual(Geometry.median([9, 1, 3, 5]), 4)
    }
    func testPixelConversionPreservesAnatomicalDataAndAspectRatio() {
        let point = Geometry.pixelPoint(CGPoint(x: 0.25, y: 0.75), size: CGSize(width: 720, height: 1280))
        XCTAssertEqual(point.x, 180)
        XCTAssertEqual(point.y, 960)
    }
    func testDisplayMirrorsOnceAndFlipsYOnlyForDrawing() {
        let point = Geometry.displayPoint(CGPoint(x: 180, y: 960), image: CGSize(width: 720, height: 1280),
                                          view: CGSize(width: 360, height: 640))
        XCTAssertEqual(point.x, 270)
        XCTAssertEqual(point.y, 160)
    }
}

final class SignalFilterTests: XCTestCase {
    func testHeldJointsRemovedAfterTwoFrames() {
        var filter = SignalFilter()
        _ = filter.apply(TestFrames.frame(t: 0))
        for count in 1...3 {
            var raw = TestFrames.frame(t: Double(count) / 30)
            raw.joints[.rightElbow]?.confidence = 0.1
            let frame = filter.apply(raw)
            if count <= 2 { XCTAssertEqual(frame.joints[.rightElbow]?.isImputed, true) }
            else { XCTAssertNil(frame.joints[.rightElbow]) }
        }
    }
    func testTimeBasedSmoothing() {
        var filter = SignalFilter()
        _ = filter.apply(TestFrames.frame(t: 0))
        var raw = TestFrames.frame(t: 1.0 / 30)
        raw.joints[.rightHip]?.position.x += 100
        let result = filter.apply(raw)
        let alpha = 1 - exp(-(1.0 / 30) / Parameters.smoothingTau)
        XCTAssertEqual(result.joints[.rightHip]!.position.x, 460 + 100 * alpha, accuracy: 0.0001)
    }
    func testLongGapResetsSmoothing() {
        var filter = SignalFilter()
        _ = filter.apply(TestFrames.frame(t: 0))
        var raw = TestFrames.frame(t: 1)
        raw.joints[.rightHip]?.position.x = 550
        XCTAssertEqual(filter.apply(raw).joints[.rightHip]?.position.x, 550)
    }
    func testMultiplePeopleFlagSurvivesFilter() {
        var filter = SignalFilter()
        var frame = TestFrames.frame(t: 0)
        frame.multiplePeople = true
        XCTAssertTrue(filter.apply(frame).multiplePeople)
    }
    func testConfidenceTiersAndFreshness() {
        var filter = SignalFilter()
        var frame = TestFrames.frame(t: 0)
        frame.joints[.rightShoulder]?.confidence = 0.3
        frame.joints[.rightElbow]?.confidence = 0.49
        let result = filter.apply(frame)
        XCTAssertNotNil(result.joints[.rightShoulder])
        XCTAssertNil(result.joints[.rightElbow])
    }
}

@MainActor
final class TiltFreshnessTests: XCTestCase {
    func testNoMotionReadingIsNeverUpright() {
        let tilt = TiltMonitor()
        XCTAssertNil(tilt.freshTilt)
        tilt.stop()
        XCTAssertNil(tilt.freshTilt)
    }
}
