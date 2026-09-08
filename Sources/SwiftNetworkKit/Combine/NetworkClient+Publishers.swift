#if canImport(Combine)
import Foundation
import Combine

public extension NetworkClient {

    /// A publisher for one request: emits the decoded response then completes, or completes with a
    /// ``NetworkError``. Cancelling the subscription cancels the underlying `Task`.
    ///
    /// Values arrive on whatever executor the request finished on — call `.receive(on: RunLoop.main)`
    /// (or `DispatchQueue.main`) yourself before binding to UI.
    func publisher<E: Endpoint>(for endpoint: E) -> AnyPublisher<E.Response, NetworkError> {
        makePublisher { send in
            send(try await self.request(endpoint))
        }
    }

    /// A publisher that emits each page's items, then completes.
    func paginatePublisher<E: PaginatedEndpoint>(_ endpoint: E) -> AnyPublisher<[E.Item], NetworkError> {
        makePublisher { send in
            for try await page in self.paginate(endpoint) { send(page) }
        }
    }

    /// A publisher that emits ascending ``UploadState/progress(_:)`` then ``UploadState/finished(_:)``.
    func uploadPublisher<E: Endpoint>(
        _ endpoint: E,
        from body: UploadBody
    ) -> AnyPublisher<UploadState<E.Response>, NetworkError> {
        makePublisher { send in
            let response = try await self.upload(endpoint, from: body) { send(.progress($0)) }
            send(.finished(response))
        }
    }

    /// A publisher that emits ascending ``DownloadState/progress(_:)`` then ``DownloadState/finished(_:)``.
    func downloadPublisher<E: Endpoint>(
        _ endpoint: E,
        to destination: URL? = nil
    ) -> AnyPublisher<DownloadState, NetworkError> {
        makePublisher { send in
            let url = try await self.download(endpoint, to: destination) { send(.progress($0)) }
            send(.finished(url))
        }
    }

    // MARK: - Bridge

    private func makePublisher<Output: Sendable>(
        _ work: @escaping @Sendable (@escaping @Sendable (Output) -> Void) async throws -> Void
    ) -> AnyPublisher<Output, NetworkError> {
        Deferred {
            let box = PublisherBox<Output>()
            return box.subject
                .handleEvents(
                    receiveSubscription: { _ in
                        box.task = Task {
                            do {
                                try await work { box.send($0) }
                                box.finish(.finished)
                            } catch {
                                box.finish(.failure(NetworkError.normalize(error)))
                            }
                        }
                    },
                    receiveCancel: { box.task?.cancel() }
                )
        }
        .eraseToAnyPublisher()
    }
}

/// Serializes `PassthroughSubject.send` (called from progress callbacks on arbitrary threads) and
/// holds the driving `Task` so a cancelled subscription tears it down.
private final class PublisherBox<Output>: @unchecked Sendable {
    let subject = PassthroughSubject<Output, NetworkError>()
    var task: Task<Void, Never>?
    private let lock = NSLock()

    func send(_ value: Output) {
        lock.withLock { subject.send(value) }
    }

    func finish(_ completion: Subscribers.Completion<NetworkError>) {
        lock.withLock { subject.send(completion: completion) }
    }
}
#endif
