import Foundation

/// What an upload publisher emits: progress updates, then the decoded response.
public enum UploadState<Response: Sendable>: Sendable {
    case progress(ProgressEvent)
    case finished(Response)
}

/// What a download publisher emits: progress updates, then the local file URL.
public enum DownloadState: Sendable {
    case progress(ProgressEvent)
    case finished(URL)
}
