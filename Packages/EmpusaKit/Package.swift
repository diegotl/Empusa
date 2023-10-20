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
        .package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2"),
        .package(path: "../EmpusaMacros")
    ],
    targets: [
        .target(
            name: "EmpusaKit",
            dependencies: [
                .product(name: "Zip", package: "Zip"),
                .product(name: "EmpusaMacros", package: "EmpusaMacros")
            ]
        ),
        .testTarget(
            name: "EmpusaKitTests",
            dependencies: ["EmpusaKit"]),
    ]
)
