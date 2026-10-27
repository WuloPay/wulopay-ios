import XCTest
@testable import WuloPayCheckout

final class CheckoutResultTests: XCTestCase {
    func testParsesThePaidReturn() {
        let url = URL(string: "myshop://checkout?session_id=cs_7CRIaOqGBtDY1J7ARiDLS7&status=paid")!
        XCTAssertEqual(CheckoutResult.parse(url), CheckoutResult(status: .paid, sessionId: "cs_7CRIaOqGBtDY1J7ARiDLS7"))
    }

    func testTreatsUnexpectedValuesAsUnknown() {
        let url = URL(string: "myshop://checkout?session_id=%3Cscript%3E&status=hacked")!
        XCTAssertEqual(CheckoutResult.parse(url), CheckoutResult(status: .unknown, sessionId: nil))
    }

    func testAcceptsOnlyWuloPayPaymentPages() {
        XCTAssertNoThrow(try validate(url: URL(string: "https://pay.wulopay.com/c/cs_1")!, callbackScheme: "myshop", allowedHosts: []))
        XCTAssertNoThrow(try validate(url: URL(string: "https://pay-sandbox.wulopay.com/c/cs_1")!, callbackScheme: "myshop", allowedHosts: []))
        XCTAssertThrowsError(try validate(url: URL(string: "http://pay.wulopay.com/c/cs_1")!, callbackScheme: "myshop", allowedHosts: []))
        XCTAssertThrowsError(try validate(url: URL(string: "https://pay.wulopay.com.evil.example/c/cs_1")!, callbackScheme: "myshop", allowedHosts: []))
        XCTAssertNoThrow(try validate(url: URL(string: "https://pay.staging.example/c/cs_1")!, callbackScheme: "myshop", allowedHosts: ["pay.staging.example"]))
    }

    func testRejectsWebSchemesAsCallback() {
        XCTAssertThrowsError(try validate(url: URL(string: "https://pay.wulopay.com/c/cs_1")!, callbackScheme: "https", allowedHosts: []))
        XCTAssertThrowsError(try validate(url: URL(string: "https://pay.wulopay.com/c/cs_1")!, callbackScheme: "", allowedHosts: []))
    }
}
