import SwiftUI
import SwiftNetworkKit

/// Full-bleed error state with retry, driven by a `NetworkError`.
struct ErrorStateView: View {
    let error: NetworkError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: symbol)
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again", action: retry).buttonStyle(.borderedProminent)
        }
    }

    private var symbol: String {
        switch error.code {
        case .noInternet, .offline: "wifi.slash"
        case .timeout: "clock.badge.exclamationmark"
        case .notFound: "questionmark.folder"
        case .unauthorized, .forbidden, .sessionExpired: "lock.trianglebadge.exclamationmark"
        case .server, .rateLimited: "exclamationmark.icloud"
        default: "exclamationmark.triangle"
        }
    }
}
