import Foundation

/// Coordinates access-token refresh so that:
///
/// - concurrent 401s trigger **exactly one** refresh network call (single-flight),
/// - callers that arrive during a refresh **queue** on the same operation,
/// - a given original request is only retried once — a second 401 for it means the session is
///   genuinely gone (`.sessionExpired`), never an infinite loop,
/// - refresh failure clears the stored pair and fires the session-expired callback **once**.
public actor TokenManager {

    public typealias RefreshHandler = @Sendable (_ storage: any TokenStorage) async throws -> TokenPair
    public typealias SessionExpiredHandler = @Sendable () async -> Void

    private let storage: any TokenStorage
    private let refreshHandler: RefreshHandler
    private let onSessionExpired: SessionExpiredHandler
    private let proactiveLeeway: TimeInterval

    private var refreshTask: Task<TokenPair, any Error>?
    private var retriedRequestIDs: Set<RequestID> = []

    public init(
        storage: any TokenStorage,
        proactiveLeeway: TimeInterval = 60,
        refresh: @escaping RefreshHandler,
        onSessionExpired: @escaping SessionExpiredHandler = {}
    ) {
        self.storage = storage
        self.refreshHandler = refresh
        self.onSessionExpired = onSessionExpired
        self.proactiveLeeway = proactiveLeeway
    }

    /// The token to attach to an outgoing request: the stored one, unless it is known to be expiring
    /// within the proactive leeway — then a refresh happens first. `nil` when nothing is stored.
    public func tokenForOutgoingRequest() async -> String? {
        guard let pair = try? await storage.currentTokenPair() else { return nil }
        if pair.isExpired(leeway: proactiveLeeway), pair.refreshToken != nil {
            return try? await performRefresh().accessToken
        }
        return pair.accessToken
    }

    /// Refreshes after a 401 and returns the new access token. Throws `.sessionExpired` if this
    /// original request has already been retried once.
    public func refreshedToken(forRetryOf requestID: RequestID) async throws -> String {
        if retriedRequestIDs.contains(requestID) {
            await expireSession()
            throw NetworkError.sessionExpired
        }
        retriedRequestIDs.insert(requestID)
        return try await performRefresh().accessToken
    }

    /// Clears tokens and fires the session-expired callback. Idempotent-ish (safe to call twice).
    public func expireSession() async {
        try? await storage.clearTokenPair()
        await onSessionExpired()
    }

    /// Drops the per-request refresh guard once a logical request is fully done (success or failure).
    /// Keeps ``retriedRequestIDs`` from growing over the process lifetime.
    func forget(_ requestID: RequestID) {
        retriedRequestIDs.remove(requestID)
    }

    // MARK: - Single-flight

    private func performRefresh() async throws -> TokenPair {
        if let refreshTask {
            do {
                return try await refreshTask.value
            } catch {
                throw NetworkError.tokenRefreshFailed(underlying: asSendableError(error))
            }
        }

        let storage = storage
        let handler = refreshHandler
        let task = Task { try await handler(storage) }
        refreshTask = task

        do {
            let pair = try await task.value
            refreshTask = nil
            try? await storage.store(pair)
            return pair
        } catch {
            refreshTask = nil
            await expireSession()
            throw NetworkError.tokenRefreshFailed(underlying: asSendableError(error))
        }
    }
}
