// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AwareUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "AwareUI",
            targets: ["AwareUI"]
        ),
    ],
    dependencies: [
        .package(path: "../AwareData"),
    ],
    targets: [
        .target(
            name: "AwareUI",
            dependencies: [
                .product(
                    name: "AwareData",
                    package: "AwareData",
                    condition: nil
                )
            ],
            path: "."
        ),
    ]
)
