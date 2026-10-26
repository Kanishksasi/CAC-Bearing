import CoreGraphics
import Foundation

struct SignalFilter {
    private var last: [JointName: JointPoint] = [:]
    private var held: [JointName: Int] = [:]
    private var lastTime: TimeInterval?

    mutating func reset() {
        last = [:]; held = [:]; lastTime = nil
    }

    mutating func apply(_ raw: PoseFrame) -> PoseFrame {
        if let lastTime, raw.timestamp <= lastTime || raw.timestamp - lastTime > Parameters.maxGapSeconds { reset() }
        let dt = lastTime.map { max(0.001, raw.timestamp - $0) } ?? 0
        let alpha = dt > 0 ? 1 - exp(-dt / Parameters.smoothingTau) : 1
        lastTime = raw.timestamp

        var output: [JointName: JointPoint] = [:]
        for name in JointName.allCases {
            if let point = raw.joints[name], point.isFresh(for: name) {
                var smoothed = point
                if let previous = last[name], !previous.isImputed {
                    smoothed.position = CGPoint(
                        x: previous.position.x + CGFloat(alpha) * (point.position.x - previous.position.x),
                        y: previous.position.y + CGFloat(alpha) * (point.position.y - previous.position.y))
                }
                smoothed.isImputed = false
                output[name] = smoothed
                last[name] = smoothed
                held[name] = 0
            } else if var previous = last[name], (held[name] ?? 0) < Parameters.maxHeldFrames {
                previous.isImputed = true // held values do not count as fresh joints
                output[name] = previous
                last[name] = previous
                held[name] = (held[name] ?? 0) + 1
            } else {
                last[name] = nil
            }
        }
        return PoseFrame(timestamp: raw.timestamp, size: raw.size, joints: output, multiplePeople: raw.multiplePeople)
    }
}
