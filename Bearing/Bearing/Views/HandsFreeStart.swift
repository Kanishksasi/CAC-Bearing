import Foundation

struct HandsFreeStart {
    private(set) var isArmed = false
    private var readySince: TimeInterval?
    mutating func arm() { isArmed = true; readySince = nil }
    mutating func cancel() { isArmed = false; readySince = nil }
    mutating func update(ready: Bool, now: TimeInterval) -> Bool {
        guard isArmed else { return false }
        guard ready else { readySince = nil; return false }
        guard let since = readySince else { readySince = now; return false }
        guard now - since >= 2 else { return false }
        cancel()
        return true
    }
}
