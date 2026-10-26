import Combine
import CoreMotion
import Foundation

@MainActor
final class TiltMonitor: ObservableObject {
    @Published private(set) var lastDegrees: Double?
    private var lastUpdate: TimeInterval?
    private let manager = CMMotionManager()
    var onReading: ((Double?) -> Void)?

    var freshTilt: Double? {
        Self.fresh(degrees: lastDegrees, updatedAt: lastUpdate, now: ProcessInfo.processInfo.systemUptime)
    }

    func start() {
        stop()
        guard manager.isDeviceMotionAvailable else { onReading?(nil); return }
        manager.deviceMotionUpdateInterval = Parameters.minFrameInterval
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }
            guard error == nil, let gravity = motion?.gravity,
                  let value = Self.tilt(gx: gravity.x, gy: gravity.y, gz: gravity.z) else {
                self.lastDegrees = nil
                self.lastUpdate = nil
                self.onReading?(nil)
                return
            }
            self.lastDegrees = value
            self.lastUpdate = ProcessInfo.processInfo.systemUptime
            self.onReading?(value)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        lastDegrees = nil
        lastUpdate = nil
    }

    nonisolated static func fresh(degrees: Double?, updatedAt: TimeInterval?, now: TimeInterval) -> Double? {
        guard let degrees, degrees.isFinite, let updatedAt,
              now >= updatedAt, now - updatedAt < Parameters.tiltStaleSeconds else { return nil }
        return degrees
    }

    nonisolated static func tilt(gx: Double, gy: Double, gz: Double) -> Double? {
        let magnitude = (gx * gx + gy * gy + gz * gz).squareRoot()
        guard magnitude.isFinite, magnitude > 0.5 else { return nil }
        return acos(max(-1, min(1, -gy / magnitude))) * 180 / .pi
    }
}
