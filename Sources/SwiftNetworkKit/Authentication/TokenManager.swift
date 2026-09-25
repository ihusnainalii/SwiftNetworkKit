import Foundation

/// Coordinates access-token refresh so that:
///
/// - concurrent 401s trigger **exactly one** refresh network call (single-flight),
/// - callers that arrive during a refresh **queue** on the same operation,
/// - a given original request is only retried once, a second 401 for it means the session is
///   genuinely gone (`.sessionExpired`), never an infinite loop,
/// - a failed refresh clears the stored pair and fires the session-expired callback (once per failed
///   refresh, and once when a request 401s twice).
///
/// Storage failures are never mistaken for "no token": a keychain that is locked or a pair that cannot
/// be decoded surfaces as an error, and a refreshed pair that cannot be persisted fails the refresh
/// instead of leaving the stale token in place.
public actor TokenManager {

    public typealias RefreshHandler = @Sendable (_ storage: any TokenStorage) async throws -> TokenPair
    public typealias SessionExpiredHandler = @Sendable () async -> Void

    private let storage: any TokenStorage
    private let refreshHandler: RefreshHandler
    private let onSessionExpired: SessionExpiredHandler
    private let proactiveLeeway: TimeInterval
    private let logger: (any NetworkLogger)?

    private var refreshTask: Task<TokenPair, any Error>?
    private var retriedRequestIDs: Set<RequestID> = []

    /// - Parameter logger: receives a line when a storage operation the manager cannot report any
    ///   other way fails (for example clearing tokens during a session expiry).
    public init(
        storage: any TokenStorage,
        proactiveLeeway: TimeInterval = 60,
        refresh: @escaping RefreshHandler,
        onSessionExpired: @escaping SessionExpiredHandler = {},
        logger: (any NetworkLogger)? = nil
    ) {
        self.storage = storage
        self.refreshHandler = refresh
        self.onSessionExpired = onSessionExpired
        self.proactiveLeeway = proactiveLeeway
        self.logger = logger
    }

    /// The token to attach to an outgoing request: the stored one, unless it is known to be expiring
    /// within the proactive leeway, then a refresh happens first. `nil` when nothing is stored.
    ///
    /// Any failure (storage unreadable, refresh rejected) is collapsed to `nil` here. `NetworkClient`
    /// uses the throwing variant so those failures reach the caller instead.
    public func tokenForOutgoingRequest() async -> String? {
        try? await outgoingToken()
    }

    /// Like ``tokenForOutgoingRequest()`` but throws. Only "nothing stored" yields `nil`.
    func outgoingToken() async throws -> String? {
        guard let pair = try await storage.currentTokenPair() else { return nil }
        if pair.isExpired(leeway: proactiveLeeway), pair.refreshToken != nil {
            return try await performRefresh().accessToken
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

    /// Clears tokens and fires the session-expired callback. Safe to call twice.
    ///
    /// The callback runs even when the tokens cannot be cleared, because the app must still sign the
    /// user out. That failure is reported through the logger.
    public func expireSession() async {
        do {
            try await storage.clearTokenPair()
        } catch {
            logger?.log("could not clear stored tokens on session expiry: \(error)", level: .error)
        }
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

        let pair: TokenPair
        do {
            pair = try await task.value
        } catch {
            refreshTask = nil
            await expireSession()
            throw NetworkError.tokenRefreshFailed(underlying: asSendableError(error))
        }

        // The single-flight task stays registered while the pair is persisted so a concurrent caller
        // joins this refresh instead of starting a second one against the still-stale stored token.
        do {
            try await storage.store(pair)
        } catch {
            refreshTask = nil
            // The session itself may still be valid, so do not sign the user out. Fail loudly instead
            // of silently leaving the old token in storage to 401 and refresh again forever.
            throw NetworkError.tokenRefreshFailed(underlying: asSendableError(error))
        }
        refreshTask = nil
        return pair
    }
}
