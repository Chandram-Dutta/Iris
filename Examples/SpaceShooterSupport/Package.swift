// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SpaceShooterSupport",
    products: [
        .library(name: "SpaceShooterSupport", targets: ["SpaceShooterSupport"])
    ],
    targets: [
        .target(name: "SpaceShooterSupport"),
        .testTarget(name: "SpaceShooterSupportTests", dependencies: ["SpaceShooterSupport"]),
    ]
)
