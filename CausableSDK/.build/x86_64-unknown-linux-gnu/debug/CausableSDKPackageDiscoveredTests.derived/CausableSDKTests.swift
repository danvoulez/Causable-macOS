import XCTest
@testable import CausableSDKTests

fileprivate extension CausableSDKTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__CausableSDKTests = [
        ("testEd25519SignerGeneration", testEd25519SignerGeneration),
        ("testEd25519Signing", testEd25519Signing),
        ("testHexStringConversion", testHexStringConversion),
        ("testOutboxEnqueueAndRetrieve", testOutboxEnqueueAndRetrieve),
        ("testOutboxMarkFailure", testOutboxMarkFailure),
        ("testOutboxMarkSuccess", testOutboxMarkSuccess),
        ("testOutboxPendingCount", testOutboxPendingCount),
        ("testSignerPersistence", testSignerPersistence),
        ("testSpanEnvelopeEncoding", testSpanEnvelopeEncoding)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __CausableSDKTests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CausableSDKTests.__allTests__CausableSDKTests)
    ]
}