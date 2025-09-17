// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AwareData",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "AwareData",
            targets: ["AwareData"]
        ),
    ],
    targets: [
        .target(
            name: "AwareData",
            path: "."
        ),
    ]
)
