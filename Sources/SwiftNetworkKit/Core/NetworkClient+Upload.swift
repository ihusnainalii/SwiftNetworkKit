import Foundation

public extension NetworkClient {

    /// Uploads `body` as the request body of `endpoint`, reporting byte progress, and decodes the
    /// response into `E.Response`.
    ///
    /// Uploads are **not** retried and do not run the 401-refresh hop (a partial upload is unsafe to
    /// replay). Interceptors, tracing, logging and metrics still apply.
    ///
    /// ```swift
    /// var form = MultipartFormData()
    /// form.append(jpeg, name: "photo", fileName: "cat.jpg", mimeType: "image/jpeg")
    /// let created = try await client.upload(CreatePhoto(), from: .multipart(form)) { event in
    ///     print(event.fraction ?? 0)
    /// }
    /// ```
    func upload<E: Endpoint>(
        _ endpoint: E,
        from body: UploadBody,
        progress: (@Sendable (ProgressEvent) -> Void)? = nil
    ) async throws -> E.Response {
        let (request, started, requestID) = try await prepareTransfer(endpoint)
        await configuration.metrics.record(.requestStarted(requestID))

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.upload(request, from: body, progress: progress)
        } catch {
            let mapped = NetworkError.normalize(error)
            await recordFailure(mapped, requestID: requestID, status: nil, since: started)
            throw mapped
        }

        let context = ResponseContext(
            statusCode: response.statusCode,
            headers: HTTPHeaders(response.allHeaderFields),
            data: data,
            request: request
        )
        if let error = StatusCodeMapper.map(context: context, errorMapper: configuration.errorMapper) {
            await recordFailure(error, requestID: requestID, status: context.statusCode, since: started)
            throw error
        }

        let decoder = endpoint.decoder ?? configuration.defaultDecoder
        do {
            let value = try endpoint.decode(data, response: response, using: decoder)
            await configuration.metrics.record(
                .success(requestID, duration: elapsed(since: started), status: context.statusCode)
            )
            emit(logFormatter.responseLines(context, duration: elapsed(since: started), level: logLevel), level: .basic)
            return value
        } catch let error as NetworkError {
            let mapped: NetworkError = {
                if case .decoding(let underlying, nil) = error { return .decoding(underlying: underlying, context) }
                return error
            }()
            await recordFailure(mapped, requestID: requestID, status: context.statusCode, since: started)
            throw mapped
        } catch {
            let mapped = NetworkError.decoding(underlying: asSendableError(error), context)
            await recordFailure(mapped, requestID: requestID, status: context.statusCode, since: started)
            throw mapped
        }
    }

    /// Downloads `endpoint`'s response to a file, reporting byte progress, and returns its location.
    ///
    /// - Parameter destination: where to place the file. `nil` returns the transport's temp file
    ///   (valid until deleted by the OS — move it if you need it to persist). A missing parent
    ///   directory is created.
    func download<E: Endpoint>(
        _ endpoint: E,
        to destination: URL? = nil,
        progress: (@Sendable (ProgressEvent) -> Void)? = nil
    ) async throws -> URL {
        let (request, started, requestID) = try await prepareTransfer(endpoint)
        await configuration.metrics.record(.requestStarted(requestID))

        let fileURL: URL
        let response: HTTPURLResponse
        do {
            (fileURL, response) = try await transport.download(request, progress: progress)
        } catch {
            let mapped = NetworkError.normalize(error)
            await recordFailure(mapped, requestID: requestID, status: nil, since: started)
            throw mapped
        }

        let context = ResponseContext(
            statusCode: response.statusCode,
            headers: HTTPHeaders(response.allHeaderFields),
            data: nil,
            request: request
        )
        if let error = StatusCodeMapper.map(context: context, errorMapper: configuration.errorMapper) {
            try? FileManager.default.removeItem(at: fileURL)
            await recordFailure(error, requestID: requestID, status: context.statusCode, since: started)
            throw error
        }

        await configuration.metrics.record(
            .success(requestID, duration: elapsed(since: started), status: context.statusCode)
        )
        emit(logFormatter.responseLines(context, duration: elapsed(since: started), level: logLevel), level: .basic)

        guard let destination else { return fileURL }
        do {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: fileURL, to: destination)
            return destination
        } catch {
            throw NetworkError.transport(underlying: asSendableError(error))
        }
    }

    // MARK: - Shared setup

    private func prepareTransfer<E: Endpoint>(
        _ endpoint: E
    ) async throws -> (URLRequest, ContinuousClock.Instant, RequestID) {
        if Task.isCancelled { throw NetworkError.cancelled }
        let anyEndpoint = AnyEndpoint(endpoint)
        var request = try RequestBuilder.build(
            endpoint: endpoint,
            environment: configuration.environment,
            configuration: configuration
        )
        try await authorize(&request, for: endpoint)
        request = try await interceptors.adapt(request, for: anyEndpoint)
        let started = configuration.clock.now()
        emit(logFormatter.requestLines(request, endpoint: anyEndpoint, level: logLevel), level: .basic)
        return (request, started, RequestID())
    }
}
