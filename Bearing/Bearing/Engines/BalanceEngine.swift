import Foundation

final class BalanceEngine: MovementEngine {
    private var tracker: RoutineTracker
    private var start: Double?
    private var end: Double?
    private var last = 0.0
    private var foot: Side?
    private var switched = false
    private var hips: [Double] = []
    private var widths: [Double] = []
    var isComplete: Bool { end != nil || start.map { last - $0 >= Parameters.balanceHoldCap } == true }

    init(startTime: Double? = nil) {
        tracker = RoutineTracker(required: Exercise.balance.requiredJoints(side: .right), start: startTime)
    }
    func observeTilt(_ degrees: Double?) { tracker.observeTilt(degrees) }
    func ingest(_ frame: PoseFrame, tiltDegrees: Double?) {
        guard tracker.ingest(frame, tilt: tiltDegrees), !isComplete,
              let ls = frame.joints[.leftShoulder], let rs = frame.joints[.rightShoulder],
              let lh = frame.joints[.leftHip], let rh = frame.joints[.rightHip],
              let la = frame.joints[.leftAnkle], let ra = frame.joints[.rightAnkle] else { return }
        last = frame.timestamp
        let higher: Side = la.position.y > ra.position.y ? .left : .right
        let planted = higher == .left ? ra.position : la.position
        let plantedHip = higher == .left ? rh.position : lh.position
        let leg = hypot(plantedHip.x - planted.x, plantedHip.y - planted.y)
        guard leg > 0 else { return }
        let ratio = Double(abs(la.position.y - ra.position.y) / leg)
        if start == nil {
            guard ratio >= Parameters.balanceLiftStart else { return }
            start = frame.timestamp; foot = higher
        } else {
            if ratio < Parameters.balanceLiftEnd { end = frame.timestamp; return }
            if higher != foot { switched = true; end = frame.timestamp; return }
        }
        hips.append(Double(Geometry.midpoint(lh.position, rh.position).x))
        widths.append(Double(hypot(ls.position.x - rs.position.x, ls.position.y - rs.position.y)))
    }
    func finish(endTime: Double? = nil) -> AttemptResult {
        func rejected(_ reason: NotCountedReason) -> AttemptResult { AttemptResult(side: foot ?? .right, counted: false, peakAngle: nil, reason: reason) }
        if let reason = tracker.rejection(end: endTime) { return rejected(reason) }
        if switched { return rejected(.footChanged) }
        guard let start, let foot, hips.count >= 2, !widths.isEmpty else { return rejected(.noLift) }
        let width = widths.reduce(0, +) / Double(widths.count)
        let duration = min((end ?? last) - start, Parameters.balanceHoldCap)
        guard duration >= 0.5, width > 0 else { return rejected(.noLift) }
        let mean = hips.reduce(0, +) / Double(hips.count)
        let variance = hips.reduce(0) { $0 + pow($1 - mean, 2) } / Double(hips.count)
        return AttemptResult(side: foot, counted: true, peakAngle: nil, reason: nil,
                             holdSeconds: duration, swayRatio: sqrt(variance) / width, liftedFoot: foot)
    }
}
