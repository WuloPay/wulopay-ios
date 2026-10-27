// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WuloPayCheckout",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "WuloPayCheckout", targets: ["WuloPayCheckout"]),
    ],
    targets: [
        .target(name: "WuloPayCheckout"),
        .testTarget(name: "WuloPayCheckoutTests", dependencies: ["WuloPayCheckout"]),
    ]
)
