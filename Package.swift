// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Iris",
    products: [
        .library(
            name: "Iris",
            targets: ["Iris"]
        ),
        .executable(
            name: "IrisRunner",
            targets: ["IrisRunner"]
        ),
        .executable(
            name: "Breakout",
            targets: ["Breakout"]
        ),
        .executable(
            name: "Snake",
            targets: ["Snake"]
        ),
    ],
    targets: [
        .target(
            name: "Iris"
        ),
        .executableTarget(
            name: "IrisRunner",
            dependencies: ["Iris"]
        ),
        .executableTarget(
            name: "Breakout",
            dependencies: ["Iris"],
            path: "Examples/Breakout"
        ),
        .executableTarget(
            name: "Snake",
            dependencies: ["Iris"],
            path: "Examples/Snake"
        ),
        .testTarget(
            name: "IrisTests",
            dependencies: ["Iris"]
        ),
    ]
)
