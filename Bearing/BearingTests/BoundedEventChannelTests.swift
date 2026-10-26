import XCTest
@testable import Bearing

final class BoundedEventChannelTests: XCTestCase {
    func testOnlyNewestValueRemainsBuffered() async {
        let channel = BoundedEventChannel<Int>()
        let stream = channel.subscribe()
        channel.send(1); channel.send(2); channel.send(3)
        var iterator = stream.makeAsyncIterator()
        let newest = await iterator.next()
        XCTAssertEqual(newest, 3)
        channel.finish()
        let end = await iterator.next()
        XCTAssertNil(end)
    }

    func testCancelledConsumerCanBeReplacedAfterBackgrounding() async {
        let channel = BoundedEventChannel<Int>()
        let old = channel.subscribe()
        let consumer = Task {
            var iterator = old.makeAsyncIterator()
            return await iterator.next()
        }
        consumer.cancel()
        let cancelled = await consumer.value
        XCTAssertNil(cancelled)
        let restarted = channel.subscribe()
        channel.send(7)
        var iterator = restarted.makeAsyncIterator()
        let value = await iterator.next()
        XCTAssertEqual(value, 7)
        channel.finish()
    }

    func testResubscriptionEndsPreviousStream() async {
        let channel = BoundedEventChannel<Int>()
        let first = channel.subscribe()
        let second = channel.subscribe()
        var oldIterator = first.makeAsyncIterator()
        let oldValue = await oldIterator.next()
        XCTAssertNil(oldValue)
        channel.send(9)
        var newIterator = second.makeAsyncIterator()
        let newValue = await newIterator.next()
        XCTAssertEqual(newValue, 9)
        channel.finish()
    }
}
