import Foundation

/// The payload of a request.
///
/// `.json` holds a `@Sendable` encoding thunk rather than an `Encodable` value — `Encodable` is not
/// `Sendable`, so erasing to "a closure that produces `Data`" keeps the whole type `Sendable`.
/// Multipart bodies arrive in milestone M7.
public enum RequestBody: Sendable {
    case data(Data)
    case json(@Sendable () throws -> Data)
    case formURLEncoded([String: String])

    /// Builds a `.json` body from any `Encodable & Sendable` value.
    public static func json<T: Encodable & Sendable>(
        _ value: T,
        encoder: JSONEncoder = .networkKitDefault
    ) -> RequestBody {
        .json { try encoder.encode(value) }
    }

    /// Materializes the body bytes and the `Content-Type` it implies (`nil` = caller decides).
    /// Encoding failures surface as ``NetworkError/encoding(underlying:)``.
    public func encoded() throws -> (data: Data, contentType: String?) {
        switch self {
        case .data(let data):
            return (data, nil)

        case .json(let makeData):
            do {
                return (try makeData(), "application/json")
            } catch {
                throw NetworkError.encoding(underlying: asSendableError(error))
            }

        case .formURLEncoded(let fields):
            let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&="))
            let encoded = fields
                .sorted { $0.key < $1.key }
                .map { key, value -> String in
                    let name = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                    let raw = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                    return "\(name)=\(raw)"
                }
                .joined(separator: "&")
            return (Data(encoded.utf8), "application/x-www-form-urlencoded; charset=utf-8")
        }
    }
}
