import PackageDescription

let package = Package(
    name: "BakongKHQR-Fork",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BakongKHQR-Fork",
            targets: ["BakongKHQR"]
        ),
    ],
    targets: [
        .target(
            name: "BakongKHQR-Fork",
            path: "BakongKHQR/Classes"
        ),
    ]
)
