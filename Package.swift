// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BakongKHQR-Fork",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BakongKHQR-Fork",
            targets: ["BakongKHQR-Fork"]
        ),
    ],
    targets: [
        .target(
            name: "BakongKHQR-Fork",
            path: "BakongKHQR-Fork/BakongKHQR"
        ),
    ]
)
