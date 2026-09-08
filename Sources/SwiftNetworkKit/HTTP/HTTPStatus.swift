import Foundation

/// Helpers for classifying HTTP status codes.
public enum HTTPStatus {
    public static func isSuccess(_ code: Int) -> Bool { (200..<300).contains(code) }
    public static func isRedirect(_ code: Int) -> Bool { (300..<400).contains(code) }
    public static func isClientError(_ code: Int) -> Bool { (400..<500).contains(code) }
    public static func isServerError(_ code: Int) -> Bool { (500..<600).contains(code) }
}

extension Int {
    /// `true` when the receiver is a 2xx status code.
    public var isSuccessStatus: Bool { HTTPStatus.isSuccess(self) }

    /// The localized standard reason phrase for the status code (e.g. `"not found"` for 404).
    public var httpStatusName: String { HTTPURLResponse.localizedString(forStatusCode: self) }
}
