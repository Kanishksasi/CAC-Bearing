import Foundation

// Background and paused time must not count toward a manual duration.
struct ManualTimerState {
    let limit: Double
    private var accumulated = 0.0
    private var anchor: Double?
    var running: Bool { anchor != nil }
    init(limit: Double) { self.limit = limit.isFinite ? min(600, max(5, limit)) : 60 }
    func elapsed(now: Double) -> Double {
        guard now.isFinite, let anchor else { return accumulated }
        return min(limit, accumulated + max(0, now - anchor))
    }
    mutating func start(now: Double) {
        guard !running, accumulated < limit, now.isFinite else { return }
        anchor = now
    }
    mutating func pause(now: Double) { accumulated = elapsed(now: now); anchor = nil }
    mutating func reset() { accumulated = 0; anchor = nil }
    mutating func tick(now: Double) -> Double {
        let value = elapsed(now: now)
        if value >= limit { accumulated = limit; anchor = nil }
        return value
    }
}
