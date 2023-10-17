// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EmpusaKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EmpusaKit",
            targets: ["EmpusaKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2")
    ],
    targets: [
        .target(
            name: "EmpusaKit",
            dependencies: [
                .product(name: "Zip", package: "Zip")
            ]
        ),
        .testTarget(
            name: "EmpusaKitTests",
            dependencies: ["EmpusaKit"]),
    ]
)
