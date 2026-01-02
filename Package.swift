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
        .executable(
            name: "SpaceShooter",
            targets: ["SpaceShooter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.3.0")
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
            path: "Examples/Breakout",
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "Snake",
            dependencies: ["Iris"],
            path: "Examples/Snake",
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "SpaceShooter",
            dependencies: ["Iris"],
            path: "Examples/SpaceShooter",
            exclude: ["README.md"],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "IrisTests",
            dependencies: ["Iris"]
        ),
    ]
)
