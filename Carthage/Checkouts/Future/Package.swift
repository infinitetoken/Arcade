// swift-tools-version:5.0
//
//  Package.swift
//  Future
//
//  Created by Aaron Wright on 5/1/18.
//  Copyright © 2018 Aaron Wright. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "Future",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "Future",
            targets: ["Future"])
    ],
    targets: [
        .target(
            name: "Future",
            path: "Sources"),
        .testTarget(
            name: "FutureTests",
            dependencies: ["Future"],
            path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)

