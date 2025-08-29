// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LogViewer",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LogViewer",
            targets: ["LogViewer"]
        ),
    ],
    dependencies: [
      .package(
        url: "https://github.com/apple/swift-collections.git",
        .upToNextMinor(from: "1.2.0")
      ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LogViewer",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "LogViewerTests",
            dependencies: [
                "LogViewer"
            ]
        ),
    ]
)
