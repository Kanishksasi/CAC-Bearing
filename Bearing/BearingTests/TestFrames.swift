import CoreGraphics
@testable import Bearing

enum TestFrames {
    static func frame(t: Double, angle: Double = 10, side: Side = .right) -> PoseFrame {
        var joints: [JointName: JointPoint] = [:]
        func put(_ name: JointName, _ x: Double, _ y: Double) {
            joints[name] = JointPoint(position: CGPoint(x: x, y: y), confidence: 0.99, isImputed: false)
        }
        put(.leftShoulder, 260, 900); put(.rightShoulder, 460, 900)
        put(.leftHip, 260, 600); put(.rightHip, 460, 600)
        put(.leftElbow, 230, 700); put(.rightElbow, 490, 700)
        let radians = angle * .pi / 180
        let x = side == .right ? 460.0 : 260.0
        put(side == .right ? .rightElbow : .leftElbow,
            x + (side == .right ? 1 : -1) * 200 * sin(radians), 900 - 200 * cos(radians))
        return PoseFrame(timestamp: t, size: CGSize(width: 720, height: 1280), joints: joints)
    }

    static func angle(at t: Double) -> Double {
        if t < 2 { return 10 + 55 * t }
        if t < 3 { return 120 }
        if t < 5 { return 120 - 55 * (t - 3) }
        return 10
    }

    static func run(_ engine: ArmRaiseEngine, hz: Int = 30,
                    tilt: (Double) -> Double? = { _ in 1 },
                    modify: (Double, inout PoseFrame) -> Void = { _, _ in }) {
        for i in 0..<(6 * hz) {
            let time = Double(i) / Double(hz)
            var frame = frame(t: time, angle: angle(at: time), side: engine.side)
            modify(time, &frame)
            engine.ingest(frame, tiltDegrees: tilt(time))
        }
    }
}
