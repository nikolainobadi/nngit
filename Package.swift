// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nngit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "nngit",
            targets: ["nngit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kareman/SwiftShell", from: "5.0.0"),
        .package(url: "https://github.com/nikolainobadi/NnGitKit.git", from: "0.5.0"),
        .package(url: "https://github.com/nikolainobadi/NnConfigKit.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/nikolainobadi/SwiftPicker.git", branch: "picker-protocol"),
    ],
    targets: [
        .executableTarget(
            name: "nngit",
            dependencies: [
                "SwiftShell",
                "NnConfigKit",
                "SwiftPicker",
                .product(name: "GitShellKit", package: "NnGitKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "nngitTests",
            dependencies: [
                "nngit"
            ]
        )
    ]
)
