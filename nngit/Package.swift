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
            targets: ["nngit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nikolainobadi/NnShellKit.git", from: "2.2.0"),
        .package(url: "https://github.com/nikolainobadi/NnConfigKit.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/nikolainobadi/SwiftPickerKit.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "nngit",
            dependencies: [
                "NnConfigKit",
                .product(name: "NnShellKit", package: "NnShellKit"),
                .product(name: "SwiftPickerKit", package: "SwiftPickerKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "nngitTests",
            dependencies: [
                "nngit",
                .product(name: "NnShellTesting", package: "NnShellKit"),
                .product(name: "SwiftPickerTesting", package: "SwiftPickerKit")
            ]
        ),
    ]
)
