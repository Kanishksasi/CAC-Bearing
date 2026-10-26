import CoreGraphics
import Foundation

enum NotCountedReason: String, Codable, CaseIterable, Sendable {
    case tilt, motionUnavailable, lowConfidence, outOfFrame, trunkLean, noClearRaise, noLift, footChanged, incompleteMovement

    var message: String {
        switch self {
        case .tilt: return Strings.reasonTilt
        case .motionUnavailable: return Strings.reasonMotionUnavailable
        case .lowConfidence: return Strings.reasonLowConfidence
        case .outOfFrame: return Strings.reasonOutOfFrame
        case .trunkLean: return Strings.reasonTrunkLean
        case .noClearRaise: return Strings.reasonNoClearRaise
        case .noLift: return Loc.t("We did not record a foot lift. Lower both feet and try again only if comfortable.")
        case .incompleteMovement: return Loc.t("We could not record the full movement. Review the setup and try only as comfortable.")
        case .footChanged: return Loc.t("The lifted foot changed. Start again with both feet down.")
        }
    }
}

struct AttemptResult: Sendable {
    let side: Side
    let counted: Bool
    let peakAngle: Double?
    let reason: NotCountedReason?
    var durationSeconds: Double? = nil
    var repetitions: Int? = nil
    var holdSeconds: Double? = nil
    var swayRatio: Double? = nil
    var liftedFoot: Side? = nil
}

final class ArmRaiseEngine: MovementEngine {
    private struct Sample {
        let time: TimeInterval
        let angle: Double?
        let lean: Double?
        let nearEdge: Bool
        let tilt: Double?
        let multiplePeople: Bool
    }

    let side: Side
    let exercise: Exercise
    private let startTime: TimeInterval?
    private var samples: [Sample] = []
    private var discontinuity = false
    private var motionUnavailable = false
    private var hasMotionReading = false
    private var excessiveTilt = false

    init(side: Side, startTime: TimeInterval? = nil, exercise: Exercise = .armRaise) {
        self.exercise = exercise
        self.side = side
        self.startTime = startTime
    }

    static func requiredJoints(for side: Side) -> Set<JointName> {
        [.leftShoulder, .rightShoulder, .leftHip, .rightHip,
         side == .right ? .rightElbow : .leftElbow]
    }

    func observeTilt(_ degrees: Double?) {
        guard let degrees, degrees.isFinite, degrees >= 0 else { motionUnavailable = true; return }
        hasMotionReading = true
        if degrees > Parameters.tiltLimitDegrees { excessiveTilt = true }
    }

    func ingest(_ frame: PoseFrame, tiltDegrees: Double?) {
        if let startTime, frame.timestamp < startTime { return }
        observeTilt(tiltDegrees)
        guard frame.timestamp.isFinite else { discontinuity = true; return }
        if let previous = samples.last, frame.timestamp <= previous.time {
            discontinuity = true
            return
        }
        let required = exercise.requiredJoints(side: side)
        let fresh = !frame.multiplePeople && required.allSatisfy {
            frame.joints[$0]?.isFresh(for: $0) == true
        }
        let sizeOK = frame.size.width > 0 && frame.size.height > 0
        let edge = required.contains { joint in
            guard let point = frame.joints[joint]?.position else { return false }
            let margin = Parameters.edgeMargin
            return point.x < frame.size.width * margin || point.x > frame.size.width * (1 - margin)
                || point.y < frame.size.height * margin || point.y > frame.size.height * (1 - margin)
        }
        var angle: Double?
        var lean: Double?
        if fresh && sizeOK,
           let shoulder = frame.joints[.shoulder(side)], let hip = frame.joints[.hip(side)] {
            if exercise == .kneeBend, let knee = frame.joints[.knee(side)], let ankle = frame.joints[.ankle(side)],
               let interior = Geometry.angleDegrees(vertex: knee.position, a: hip.position, b: ankle.position) {
                angle = 180 - interior
            } else if let elbow = frame.joints[.elbow(side)] {
                angle = Geometry.angleDegrees(vertex: shoulder.position, a: hip.position, b: elbow.position)
            }
            if exercise == .armRaise,
               let ls = frame.joints[.leftShoulder], let rs = frame.joints[.rightShoulder],
               let lh = frame.joints[.leftHip], let rh = frame.joints[.rightHip] {
                lean = Geometry.leanFromVerticalDegrees(top: Geometry.midpoint(ls.position, rs.position), bottom: Geometry.midpoint(lh.position, rh.position))
            } else if exercise == .shoulderReach {
                lean = Geometry.leanFromVerticalDegrees(top: shoulder.position, bottom: hip.position)
            }
        }
        let tilt = tiltDegrees.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        samples.append(Sample(time: frame.timestamp, angle: angle, lean: lean,
                              nearEdge: edge, tilt: tilt, multiplePeople: frame.multiplePeople))
    }

    func finish(endTime: TimeInterval? = nil) -> AttemptResult {
        func reject(_ reason: NotCountedReason, peak: Double? = nil) -> AttemptResult {
            AttemptResult(side: side, counted: false, peakAngle: peak, reason: reason)
        }
        guard !motionUnavailable, hasMotionReading, !samples.contains(where: { $0.tilt == nil }) else {
            return reject(.motionUnavailable)
        }
        if excessiveTilt || samples.contains(where: { ($0.tilt ?? .infinity) > Parameters.tiltLimitDegrees }) { return reject(.tilt) }
        guard !samples.isEmpty else { return reject(.lowConfidence) }
        if discontinuity || samples.contains(where: { $0.multiplePeople }) { return reject(.lowConfidence) }
        // Include the boundaries so a camera stall cannot disappear from the check.
        if let first = samples.first, let last = samples.last {
            if let startTime, first.time - startTime > Parameters.maxGapSeconds { return reject(.lowConfidence) }
            if let endTime, endTime - last.time > Parameters.maxGapSeconds { return reject(.lowConfidence) }
            for pair in zip(samples, samples.dropFirst()) where pair.1.time - pair.0.time > Parameters.maxGapSeconds {
                return reject(.lowConfidence)
            }
        }
        let fresh = samples.filter { $0.angle != nil }
        guard fresh.count >= Parameters.topSamplesForPeak,
              Double(fresh.count) / Double(samples.count) >= Parameters.minValidFrameFraction else {
            return reject(samples.contains(where: { $0.nearEdge }) ? .outOfFrame : .lowConfidence)
        }
        let angles = fresh.compactMap(\.angle)
        let top = fresh.enumerated().sorted {
            if $0.element.angle == $1.element.angle { return $0.offset < $1.offset }
            return ($0.element.angle ?? 0) > ($1.element.angle ?? 0)
        }.prefix(Parameters.topSamplesForPeak)
        let ranked = Array(top)
        let peakIndex = ranked[ranked.count / 2].offset
        guard let peak = Geometry.median(ranked.compactMap { $0.element.angle }) else { return reject(.lowConfidence) }
        let low = exercise == .kneeBend ? Parameters.kneeLowDegrees : Parameters.startLowDegrees
        let raised = exercise == .kneeBend ? Parameters.kneeRaiseDegrees : Parameters.minRaiseDegrees
        guard angles[0] < low, peak >= raised,
              peakIndex > 0,
              let endIndex = angles[peakIndex...].firstIndex(where: { $0 < low }),
              endIndex > peakIndex else { return reject(exercise == .armRaise ? .noClearRaise : .incompleteMovement, peak: peak) }
        let sequence = Array(fresh[...endIndex])
        let first = sequence[0].time, last = sequence[sequence.count - 1].time
        if samples.contains(where: { $0.time >= first && $0.time <= last && $0.nearEdge }) {
            return reject(.outOfFrame, peak: peak)
        }
        for (a, b) in zip(sequence, sequence.dropFirst()) {
            let gap = b.time - a.time
            if gap > Parameters.maxGapSeconds { return reject(.lowConfidence, peak: peak) }
            if gap > Parameters.jumpGapSeconds, abs((b.angle ?? 0) - (a.angle ?? 0)) > Parameters.maxJumpAcrossGapDegrees {
                return reject(.lowConfidence, peak: peak)
            }
        }
        let duration = last - first
        guard duration > 0, Double(sequence.count - 1) / duration >= Parameters.minValidRateHz else {
            return reject(.lowConfidence, peak: peak)
        }
        let peakTime = fresh[peakIndex].time
        if samples.filter({ abs($0.time - peakTime) <= Parameters.peakWindowSeconds })
            .compactMap(\.lean).contains(where: { $0 > Parameters.trunkLeanLimitDegrees }) {
            return reject(.trunkLean, peak: peak)
        }
        return AttemptResult(side: side, counted: true, peakAngle: peak, reason: nil)
    }
}
