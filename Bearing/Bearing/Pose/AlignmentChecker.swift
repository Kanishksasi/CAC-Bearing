import CoreGraphics
import Foundation

enum FramingState { case ok, tooFar, tooClose, outOfFrame, unknown }

struct AlignmentStatus {
    var singlePerson = true
    var jointsVisible = false
    var framing: FramingState = .unknown
    var tiltOK = false
    var stable = false

    // Ready means setup checks passed, not that the measurement is accurate.
    var isReady: Bool { singlePerson && jointsVisible && framing == .ok && tiltOK && stable }

    var firstFix: String? {
        if !singlePerson { return Strings.fixOnePerson }
        if !jointsVisible { return Strings.fixJoints }
        switch framing {
        case .tooFar: return Strings.fixStepCloser
        case .tooClose, .outOfFrame: return Strings.fixStepBack
        default: break
        }
        if !tiltOK { return Strings.fixTilt }
        if !stable { return Strings.fixStill }
        return nil
    }

    static let empty = AlignmentStatus()
}

// Shoulder height can differ; it is not a start condition.
struct AlignmentChecker {
    private var history: [(t: TimeInterval, x: Double, y: Double)] = []

    mutating func reset() { history = [] }

    // Missing or stale motion data blocks Start.
    mutating func evaluate(frame: PoseFrame, tiltDegrees: Double?, exercise: Exercise = .armRaise, side: Side = .right) -> AlignmentStatus {
        var status = AlignmentStatus()
        status.singlePerson = !frame.multiplePeople
        status.tiltOK = tiltDegrees.map { $0.isFinite && $0 >= 0 && $0 <= Parameters.tiltLimitDegrees } ?? false

        let required = exercise.requiredJoints(side: side, setup: true)
        let points = required.compactMap { name -> CGPoint? in
            guard let p = frame.joints[name], p.isFresh(for: name) else { return nil }
            return p.position
        }
        status.jointsVisible = points.count == required.count
        guard status.singlePerson, status.jointsVisible, !points.isEmpty else { history = []; return status }
        let shoulderMid: CGPoint
        let hipMid: CGPoint
        if exercise.isSideView,
           let shoulder = frame.joints[.shoulder(side)]?.position,
           let hip = frame.joints[.hip(side)]?.position {
            shoulderMid = shoulder; hipMid = hip
        } else if let ls = frame.joints[.leftShoulder]?.position, let rs = frame.joints[.rightShoulder]?.position,
                  let lh = frame.joints[.leftHip]?.position, let rh = frame.joints[.rightHip]?.position {
            shoulderMid = Geometry.midpoint(ls, rs); hipMid = Geometry.midpoint(lh, rh)
        } else { history = []; return status }

        guard frame.size.width > 0, frame.size.height > 0, frame.timestamp.isFinite else { history = []; return status }
        let w = frame.size.width, h = frame.size.height, m = Parameters.edgeMargin
        let nearEdge = points.contains { $0.x < w * m || $0.x > w * (1 - m) || $0.y < h * m || $0.y > h * (1 - m) }
        let fullBody = exercise == .balance || exercise == .kneeBend
        let span = fullBody ? ((points.map(\.y).max() ?? 0) - (points.map(\.y).min() ?? 0)) / h
            : abs(hipMid.y - shoulderMid.y) / h
        let spanMin = fullBody ? 0.45 : Parameters.spanMin
        let spanMax = fullBody ? 0.90 : Parameters.spanMax
        if nearEdge { status.framing = .outOfFrame }
        else if span < spanMin { status.framing = .tooFar }
        else if span > spanMax { status.framing = .tooClose }
        else { status.framing = .ok }

        let center = Geometry.midpoint(shoulderMid, hipMid)
        guard status.tiltOK, status.framing == .ok else { history = []; return status }
        if let last = history.last, frame.timestamp <= last.t || frame.timestamp - last.t > Parameters.maxGapSeconds { history = [] }
        history.append((frame.timestamp, Double(center.x / w), Double(center.y / h)))
        history.removeAll { frame.timestamp - $0.t > Parameters.stableSeconds + 0.1 }
        let covered = frame.timestamp - (history.first?.t ?? frame.timestamp)
        let xs = history.map { $0.x }, ys = history.map { $0.y }
        let spreadX = (xs.max() ?? 0) - (xs.min() ?? 0)
        let spreadY = (ys.max() ?? 0) - (ys.min() ?? 0)
        status.stable = covered + 1e-9 >= Parameters.stableSeconds
            && spreadX < Parameters.stableMaxMove && spreadY < Parameters.stableMaxMove
        return status
    }
}
