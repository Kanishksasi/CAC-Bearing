import Foundation

protocol MovementEngine: AnyObject {
    var isComplete: Bool { get }
    func observeTilt(_ degrees: Double?)
    func ingest(_ frame: PoseFrame, tiltDegrees: Double?)
    func finish(endTime: TimeInterval?) -> AttemptResult
}

extension MovementEngine { var isComplete: Bool { false } }

struct RoutineTracker {
    let required: Set<JointName>
    let start: TimeInterval?
    init(required: Set<JointName>, start: Double?) { self.required = required; self.start = start }
    private var times: [Double] = []
    private var freshTimes: [Double] = []
    private var invalidTilt = false
    private var missingTilt = false
    private var seenTilt = false
    private var discontinuity = false
    private var outOfFrame = false

    mutating func observeTilt(_ value: Double?) {
        guard let value, value.isFinite, value >= 0 else { missingTilt = true; return }
        seenTilt = true
        if value > Parameters.tiltLimitDegrees { invalidTilt = true }
    }

    mutating func ingest(_ frame: PoseFrame, tilt: Double?) -> Bool {
        if let start, frame.timestamp < start { return false }
        observeTilt(tilt)
        guard frame.timestamp.isFinite else { discontinuity = true; return false }
        if let last = times.last, frame.timestamp <= last { discontinuity = true; return false }
        times.append(frame.timestamp)
        guard !frame.multiplePeople else { discontinuity = true; return false }
        guard frame.size.width > 0, frame.size.height > 0,
              required.allSatisfy({ frame.joints[$0]?.isFresh(for: $0) == true }) else { return false }
        let edge = required.contains { name in
            let p = frame.joints[name]!.position, m = Parameters.edgeMargin
            return p.x < frame.size.width * m || p.x > frame.size.width * (1 - m)
                || p.y < frame.size.height * m || p.y > frame.size.height * (1 - m)
        }
        if edge { outOfFrame = true; return false }
        freshTimes.append(frame.timestamp)
        return true
    }

    func rejection(end: Double?) -> NotCountedReason? {
        if missingTilt || !seenTilt { return .motionUnavailable }
        if invalidTilt { return .tilt }
        if outOfFrame { return .outOfFrame }
        guard !discontinuity, times.count >= 2, freshTimes.count >= 2,
              Double(freshTimes.count) / Double(times.count) >= Parameters.minValidFrameFraction,
              let first = freshTimes.first, let last = freshTimes.last, last > first else { return .lowConfidence }
        if let start, first - start > Parameters.maxGapSeconds { return .lowConfidence }
        if let end, end - last > Parameters.maxGapSeconds { return .lowConfidence }
        if zip(freshTimes, freshTimes.dropFirst()).contains(where: { $1 - $0 > Parameters.maxGapSeconds }) { return .lowConfidence }
        if Double(freshTimes.count - 1) / (last - first) < Parameters.minValidRateHz { return .lowConfidence }
        return nil
    }
}

final class JointAngleEngine: MovementEngine {
    private let engine: ArmRaiseEngine
    init(exercise: Exercise, side: Side, startTime: Double? = nil) {
        engine = ArmRaiseEngine(side: side, startTime: startTime, exercise: exercise)
    }
    func observeTilt(_ degrees: Double?) { engine.observeTilt(degrees) }
    func ingest(_ frame: PoseFrame, tiltDegrees: Double?) { engine.ingest(frame, tiltDegrees: tiltDegrees) }
    func finish(endTime: Double? = nil) -> AttemptResult { engine.finish(endTime: endTime) }
}
