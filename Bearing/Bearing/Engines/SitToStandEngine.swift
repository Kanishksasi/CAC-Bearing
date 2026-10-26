import Foundation

final class SitToStandEngine: MovementEngine {
    private var tracker: RoutineTracker
    private var calibration: [Double] = []
    private var calibrationStart: Double?
    private var seated: Double?
    private var standing = false
    private var stands = 0
    private var first: Double?
    private var last: Double?

    init(startTime: Double? = nil) {
        tracker = RoutineTracker(required: Exercise.sitToStand.requiredJoints(side: .right), start: startTime)
    }
    func observeTilt(_ degrees: Double?) { tracker.observeTilt(degrees) }
    func ingest(_ frame: PoseFrame, tiltDegrees: Double?) {
        guard tracker.ingest(frame, tilt: tiltDegrees),
              let ls = frame.joints[.leftShoulder], let rs = frame.joints[.rightShoulder],
              let lh = frame.joints[.leftHip], let rh = frame.joints[.rightHip] else { return }
        first = first ?? frame.timestamp; last = frame.timestamp
        let shoulder = Geometry.midpoint(ls.position, rs.position), hip = Geometry.midpoint(lh.position, rh.position)
        let length = hypot(shoulder.x - hip.x, shoulder.y - hip.y)
        guard length > 0 else { return }
        let height = Double(hip.y / length)
        guard let seated else {
            calibrationStart = calibrationStart ?? frame.timestamp
            calibration.append(height)
            if frame.timestamp - (calibrationStart ?? frame.timestamp) >= Parameters.standCalibrationSeconds, calibration.count >= 8 {
                self.seated = calibration.reduce(0, +) / Double(calibration.count)
            }
            return
        }
        let rise = height - seated
        if !standing && rise >= Parameters.standRise { standing = true; stands += 1 }
        else if standing && rise <= Parameters.sitReturn { standing = false }
    }
    func finish(endTime: Double? = nil) -> AttemptResult {
        if let reason = tracker.rejection(end: endTime) { return AttemptResult(side: .right, counted: false, peakAngle: nil, reason: reason) }
        guard seated != nil, let first, let last, last - first >= Parameters.sitToStandSeconds - Parameters.maxGapSeconds else {
            return AttemptResult(side: .right, counted: false, peakAngle: nil, reason: .lowConfidence)
        }
        return AttemptResult(side: .right, counted: true, peakAngle: nil, reason: nil, repetitions: stands)
    }
}
