import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("Bounded status streams")
struct BoundedStreamTests {

    @Test("a subscriber that never reads holds only the newest updates")
    func slowSubscriberKeepsNewest() async {
        let broadcaster = NetworkStatusBroadcaster(initial: .requiresConnection)
        let stream = await broadcaster.stream()

        for index in 0..<100 {
            await broadcaster.publish(index.isMultiple(of: 2) ? .unsatisfied : .satisfied(.wifi))
        }
        await broadcaster.finishAll()

        var received: [NetworkStatus] = []
        for await status in stream { received.append(status) }

        #expect(received.count == NetworkStatusBroadcaster.bufferedUpdates)
        #expect(received.last == .satisfied(.wifi))  // the last publish (index 99) is kept
    }
}
