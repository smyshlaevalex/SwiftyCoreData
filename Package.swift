// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyCoreData",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "SwiftyCoreData",
            targets: ["SwiftyCoreData"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftyCoreData",
            dependencies: []),
        .testTarget(
            name: "SwiftyCoreDataTests",
            dependencies: ["SwiftyCoreData"]),
    ]
)
