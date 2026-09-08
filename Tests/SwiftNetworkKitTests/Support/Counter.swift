import Foundation

/// A simple async-safe counter for concurrency assertions in tests.
actor Counter {
    private(set) var value = 0

    @discardableResult
    func increment() -> Int {
        value += 1
        return value
    }
}
