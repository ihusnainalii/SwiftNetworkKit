import Foundation

/// The bits of a response's `Cache-Control` header the cache layer needs.
struct CacheControl: Sendable {
    var noStore = false
    /// `no-cache` or `max-age=0` — store, but revalidate every time.
    var mustRevalidate = false
    var maxAge: TimeInterval?

    init(headers: HTTPHeaders) {
        guard let raw = headers["Cache-Control"]?.lowercased() else { return }
        let directives = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for directive in directives {
            if directive == "no-store" { noStore = true }
            if directive == "no-cache" { mustRevalidate = true }
            if directive.hasPrefix("max-age=") {
                let seconds = TimeInterval(directive.dropFirst("max-age=".count))
                maxAge = seconds
                if seconds == 0 { mustRevalidate = true }
            }
        }
    }
}
