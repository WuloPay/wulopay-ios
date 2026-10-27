import Foundation

/// What the payment page reported when it sent the shopper back to the app.
///
/// Display only: ask **your backend** for the session's real status (webhook or retrieve) before treating an order
/// as paid.
public struct CheckoutResult: Equatable, Sendable {
    public enum Status: String, Sendable {
        case paid, cancelled, expired
        /// The shopper closed the browser sheet.
        case dismissed
        case unknown
    }

    public let status: Status
    /// The checkout session id (`cs_…`), when the page reported one.
    public let sessionId: String?

    public init(status: Status, sessionId: String?) {
        self.status = status
        self.sessionId = sessionId
    }

    /// Reads the app link WuloPay opened: your returnUrl or cancelUrl plus `?session_id=…&status=…`.
    public static func parse(_ url: URL) -> CheckoutResult {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let id = items.first { $0.name == "session_id" }?.value
        let raw = items.first { $0.name == "status" }?.value ?? ""
        let status: Status = ["paid", "cancelled", "expired"].contains(raw) ? Status(rawValue: raw)! : .unknown
        let validId = id.flatMap { $0.range(of: "^cs_[0-9A-Za-z]{10,40}$", options: .regularExpression) != nil ? $0 : nil }
        return CheckoutResult(status: status, sessionId: validId)
    }
}

public enum WuloPayCheckoutError: Error, Equatable {
    /// The URL isn't an https WuloPay payment page (or an allowed host).
    case notAPaymentPage(String)
    /// The callback scheme is empty or not a valid URL scheme.
    case invalidCallbackScheme(String)
    /// The browser sheet could not be started.
    case couldNotStart
}

/// WuloPay's payment page hosts. A session URL from anywhere else is refused unless you allow its host.
public let wuloPayPageHosts: Set<String> = ["pay.wulopay.com", "pay-sandbox.wulopay.com"]

func validate(url: URL, callbackScheme: String, allowedHosts: Set<String>) throws {
    guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased(),
          wuloPayPageHosts.union(allowedHosts).contains(host) else {
        throw WuloPayCheckoutError.notAPaymentPage(url.absoluteString)
    }
    guard callbackScheme.range(of: "^[a-zA-Z][a-zA-Z0-9+.-]*$", options: .regularExpression) != nil,
          !["http", "https"].contains(callbackScheme.lowercased()) else {
        throw WuloPayCheckoutError.invalidCallbackScheme(callbackScheme)
    }
}
