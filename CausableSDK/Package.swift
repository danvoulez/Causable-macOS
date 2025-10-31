// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CausableSDK",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CausableSDK",
            targets: ["CausableSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "CausableSDK",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Crypto", package: "swift-crypto")
            ]),
        .testTarget(
            name: "CausableSDKTests",
            dependencies: ["CausableSDK"]),
    ]
)
