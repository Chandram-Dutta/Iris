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
    ],
    targets: [
        .target(
            name: "Iris"
        ),
        .executableTarget(
            name: "IrisRunner",
            dependencies: ["Iris"]
        ),
        .testTarget(
            name: "IrisTests",
            dependencies: ["Iris"]
        ),
    ]
)
