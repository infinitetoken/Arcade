// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Arcade",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "Arcade",
            targets: ["Arcade"])
    ],
    targets: [
        .target(
            name: "Arcade",
            path: "Sources"),
        .testTarget(
            name: "ArcadeTests",
            dependencies: ["Arcade"],
            path: "Tests"),
    ]
)
