import AuthenticationServices
import Foundation

/// Opens WuloPay hosted checkout in the system browser sheet (`ASWebAuthenticationSession`), so card details are
/// typed in a trusted browser and never in a web view inside your app.
///
/// ```swift
/// // Your backend creates the session with returnUrl and cancelUrl = "myshop://checkout"
/// let result = try await WuloPayCheckout.open(url: sessionURL, callbackScheme: "myshop")
/// // then ask your backend for the order's real status
/// ```
@MainActor
public enum WuloPayCheckout {
    /// - Parameters:
    ///   - url: The session `url` your backend got from WuloPay (never create sessions in the app).
    ///   - callbackScheme: The scheme of the app link your backend used as returnUrl, e.g. `"myshop"` for `myshop://checkout`.
    ///   - presentationAnchor: The window to present from; defaults to the key window.
    ///   - allowedHosts: Extra payment page hosts (e.g. a staging host).
    public static func open(url: URL, callbackScheme: String, presentationAnchor: ASPresentationAnchor? = nil,
                            allowedHosts: Set<String> = []) async throws -> CheckoutResult {
        try validate(url: url, callbackScheme: callbackScheme, allowedHosts: allowedHosts)
        let provider = AnchorProvider(anchor: presentationAnchor)
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: CheckoutResult.parse(callbackURL))
                } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(returning: CheckoutResult(status: .dismissed, sessionId: nil))
                } else {
                    continuation.resume(throwing: error ?? WuloPayCheckoutError.couldNotStart)
                }
            }
            session.presentationContextProvider = provider
            // No shared cookies needed for a checkout, and an ephemeral session skips the system
            // "wants to use … to sign in" prompt that a login flow would show.
            session.prefersEphemeralWebBrowserSession = true
            if !session.start() {
                continuation.resume(throwing: WuloPayCheckoutError.couldNotStart)
            }
            provider.session = session   // keep the session alive until it completes
        }
    }
}

@MainActor
private final class AnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let anchor: ASPresentationAnchor?
    var session: ASWebAuthenticationSession?

    init(anchor: ASPresentationAnchor?) {
        self.anchor = anchor
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            if let anchor { return anchor }
            #if canImport(UIKit)
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
            #else
            return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
            #endif
        }
    }
}

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
