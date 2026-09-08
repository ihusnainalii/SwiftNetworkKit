import Testing
@testable import SwiftNetworkKit

@Suite("HTTPStatus")
struct HTTPStatusTests {

    @Test("range classifiers")
    func ranges() {
        #expect(HTTPStatus.isSuccess(200))
        #expect(HTTPStatus.isSuccess(299))
        #expect(!HTTPStatus.isSuccess(300))

        #expect(HTTPStatus.isRedirect(304))
        #expect(HTTPStatus.isClientError(404))
        #expect(HTTPStatus.isServerError(503))
        #expect(!HTTPStatus.isServerError(404))
    }

    @Test("Int conveniences")
    func intConveniences() {
        #expect(204.isSuccessStatus)
        #expect(!404.isSuccessStatus)
        #expect(!404.httpStatusName.isEmpty)
    }
}
