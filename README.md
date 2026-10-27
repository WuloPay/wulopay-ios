# WuloPay Checkout for iOS

Open WuloPay hosted checkout from an iOS app in the system browser sheet (`ASWebAuthenticationSession`) and get the
result back through your app's URL scheme. Card details and 3-D Secure happen on WuloPay's secure payment page, in a
trusted browser, never in a web view inside your app. iOS 16+, Swift 5.9+, no dependencies.

## Install (Swift Package Manager)

Xcode: **File, Add Package Dependencies**, `https://github.com/WuloPay/wulopay-ios`, version 1.0.0 or later. Or in
`Package.swift`:

```swift
.package(url: "https://github.com/WuloPay/wulopay-ios", from: "1.0.0")
```

## Use

1. **Your backend** creates the checkout session with its API key (never the app) and sets `returnUrl` and
   `cancelUrl` to your app link, e.g. `myshop://checkout`. It returns the session `url` to the app.
2. The app opens it:

```swift
import WuloPayCheckout

let result = try await WuloPayCheckout.open(url: sessionURL, callbackScheme: "myshop")
switch result.status {
case .paid:      // show "Confirming your payment…" and ask your backend for the order status
case .dismissed, .cancelled, .expired, .unknown: break
}
```

`result.status` is what the payment page reported, for display. Mark orders paid on your server, from the
`checkout.session.completed` webhook or by retrieving the session.

The session sheet catches the `myshop://` redirect itself, so you don't need to handle it in `onOpenURL`.
For safety, `open` only accepts https URLs on WuloPay's payment hosts (add others with `allowedHosts`).

API and webhooks: [wulopay-openapi](https://github.com/WuloPay/wulopay-openapi). Sandbox keys: api@wulopay.com.
MIT licensed. Security problems: see [SECURITY.md](SECURITY.md).
