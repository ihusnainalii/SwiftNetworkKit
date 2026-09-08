/// Counts refresh-handler invocations for the diagnostics walkthrough.
actor RefreshCounter {
    private(set) var count = 0
    func bump() { count += 1 }
}
