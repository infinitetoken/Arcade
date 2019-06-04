// swift-tools-version:5.0
//
//  Package.swift
//  Arcade
//
//  Created by Aaron Wright on 5/1/18.
//  Copyright © 2018 Aaron Wright. All rights reserved.
//

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
    dependencies: [
        .package(url: "https://github.com/infinitetoken/Future", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Arcade",
            dependencies: ["Future"],
            path: "Sources"),
        .testTarget(
            name: "ArcadeTests",
            dependencies: ["Arcade"],
            path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)
