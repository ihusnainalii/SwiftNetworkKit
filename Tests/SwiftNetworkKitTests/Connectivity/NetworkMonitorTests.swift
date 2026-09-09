import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("NetworkMonitor")
struct NetworkMonitorTests {

    private func collect(
        _ stream: AsyncStream<NetworkStatus>,
        count: Int
    ) async -> [NetworkStatus] {
        var out: [NetworkStatus] = []
        for await status in stream {
            out.append(status)
            if out.count == count { break }
        }
        return out
    }

    @Test("a subscriber sees the seed then every pushed status")
    func seedThenUpdates() async {
        let monitor = MockNetworkMonitor()
        let stream = await monitor.statusUpdates()

        async let collected = collect(stream, count: 3)
        await monitor.send([.unsatisfied, .satisfied(.wifi)])

        #expect(await collected == [.requiresConnection, .unsatisfied, .satisfied(.wifi)])
        #expect(await monitor.currentStatus == .satisfied(.wifi))
    }

    @Test("two concurrent subscribers both get the full sequence")
    func twoSubscribers() async {
        let monitor = MockNetworkMonitor(initial: .unsatisfied)
        let first = await monitor.statusUpdates()
        let second = await monitor.statusUpdates()

        async let a = collect(first, count: 3)
        async let b = collect(second, count: 3)
        await monitor.send([.satisfied(.cellular), .unsatisfied])

        let expected: [NetworkStatus] = [.unsatisfied, .satisfied(.cellular), .unsatisfied]
        #expect(await a == expected)
        #expect(await b == expected)
    }

    @Test("connectionRestored fires on each offline -> online transition")
    func connectionRestored() async {
        let monitor = MockNetworkMonitor()
        let restored = await monitor.connectionRestored()

        async let count = {
            var n = 0
            for await _ in restored {
                n += 1
                if n == 2 { break }
            }
            return n
        }()

        await monitor.send([
            .satisfied(.wifi),  // was requiresConnection (offline) -> but wasOffline starts false
            .unsatisfied,
            .satisfied(.wifi),  // restore #1
            .unsatisfied,
            .satisfied(.cellular),  // restore #2
        ])

        #expect(await count == 2)
    }

    @Test("ending iteration unsubscribes")
    func unsubscribe() async {
        let monitor = MockNetworkMonitor()
        do {
            let stream = await monitor.statusUpdates()
            var iterator = stream.makeAsyncIterator()
            _ = await iterator.next()  // consume the seed
        }  // iterator + stream dropped here -> onTermination

        for _ in 0..<100 where await monitor.subscriberCount != 0 {
            await Task.yield()
        }
        #expect(await monitor.subscriberCount == 0)
    }

    @Test("finish ends all subscriptions")
    func finishAll() async {
        let monitor = MockNetworkMonitor()
        let stream = await monitor.statusUpdates()
        await monitor.finish()

        var received = 0
        for await _ in stream { received += 1 }
        #expect(received == 1)  // just the seed, then the stream ended
        #expect(await monitor.subscriberCount == 0)
    }

    @Test("NetworkStatus online helpers")
    func statusHelpers() {
        #expect(NetworkStatus.satisfied(.wifi).isOnline)
        #expect(NetworkStatus.satisfied(.wifi).connectionType == .wifi)
        #expect(!NetworkStatus.unsatisfied.isOnline)
        #expect(NetworkStatus.unsatisfied.connectionType == nil)
        #expect(!NetworkStatus.requiresConnection.isOnline)
    }

    #if canImport(Network)
    @Test("PathNetworkMonitor starts, reports a status and yields a seeded stream")
    func pathMonitor() async {
        var monitor: PathNetworkMonitor? = PathNetworkMonitor()
        let stream = await monitor!.statusUpdates()
        _ = await monitor!.currentStatus  // starts as .requiresConnection, may update from the real path

        var first: NetworkStatus?
        for await status in stream {
            first = status
            break
        }
        #expect(first != nil)
        monitor = nil  // exercises deinit (cancel + finishAll)
    }
    #endif
}
