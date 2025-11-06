// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCache",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftCache",
            targets: ["SwiftCache"]
        ),
    ],
    dependencies: [
        // No external dependencies - 100% Apple native APIs!
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "SwiftCache",
            dependencies: [],
            path: "Sources/SwiftCache"
        ),
        .testTarget(
            name: "SwiftCacheTests",
            dependencies: ["SwiftCache"],
            path: "Tests/SwiftCacheTests"
        ),
    ]
)

