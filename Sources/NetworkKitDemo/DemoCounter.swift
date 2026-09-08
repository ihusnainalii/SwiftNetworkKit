import Foundation

/// Local counter so the demo target needs no test-support code.
actor DemoCounter {
    private(set) var count = 0
    func bump() { count += 1 }
}
