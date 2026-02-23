// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BakongKHQR",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BakongKHQR",
            targets: ["BakongKHQR"]
        ),
    ],
    targets: [
        .target(
            name: "BakongKHQR",
            path: "BakongKHQR/Classes",
            resources: [
                .process("Public"),
                .process("Private")
            ],
            publicHeadersPath: "Public"
        ),
    ]
)
