// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiquidGlassKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "LiquidGlassKit",
            targets: ["LiquidGlassKit"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Lakr233/MSDisplayLink", from: "2.0.8"),
    ],
    targets: [
        .target(
            name: "LiquidGlassKit", dependencies: [
                "MSDisplayLink",
            ],
        ),
    ],
)
