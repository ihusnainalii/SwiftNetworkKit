/// One label/value line of network metrics, ready for display. Domain-pure: no SwiftNetworkKit type
/// leaks into the presentation layer.
struct MetricsRow: Identifiable, Hashable {
    var id: String { label }
    let label: String
    let value: String
}
