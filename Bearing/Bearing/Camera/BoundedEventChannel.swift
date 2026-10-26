import Foundation

// Lock only the continuation pointer, never inference.
final class BoundedEventChannel<Event: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: AsyncStream<Event>.Continuation?

    func subscribe() -> AsyncStream<Event> {
        let pair = AsyncStream<Event>.makeStream(bufferingPolicy: .bufferingNewest(1))
        lock.lock()
        let previous = continuation
        continuation = pair.continuation
        lock.unlock()
        previous?.finish()
        return pair.stream
    }

    func send(_ event: Event) {
        lock.lock()
        let current = continuation
        lock.unlock()
        current?.yield(event)
    }

    func finish() {
        lock.lock()
        let current = continuation
        continuation = nil
        lock.unlock()
        current?.finish()
    }
}
