// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LogViewer",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "LogViewer",
            targets: ["LogViewer"]
        ),
        .library(
            name: "LogViewerCore",
            targets: ["LogViewerCore"]
        ),
        .library(
            name: "LogViewerSwiftLog",
            targets: ["LogViewerSwiftLog"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMinor(from: "1.2.0")
        ),
        .package(
            url: "https://github.com/apple/swift-log.git",
            .upToNextMajor(from: "1.14.0")
        ),
    ],
    targets: [
        .target(
            name: "LogViewerCore",
            dependencies: [
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .target(
            name: "LogViewerUI",
            dependencies: [
                "LogViewerCore",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "LogViewerSwiftLog",
            dependencies: [
                "LogViewerCore",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "LogViewer",
            dependencies: [
                "LogViewerCore",
                "LogViewerUI",
            ]
        ),
        .testTarget(
            name: "LogViewerCoreTests",
            dependencies: [
                "LogViewerCore",
            ],
            resources: [
                .process("Fixtures"),
            ]
        ),
        .testTarget(
            name: "LogViewerUITests",
            dependencies: [
                "LogViewerCore",
                "LogViewerUI",
            ]
        ),
        .testTarget(
            name: "LogViewerSwiftLogTests",
            dependencies: [
                "LogViewerCore",
                "LogViewerSwiftLog",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "LogViewerTests",
            dependencies: [
                "LogViewer",
                "LogViewerCore",
            ]
        ),
    ]
)
