// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "piano_analytics",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "piano-analytics", targets: ["piano_analytics"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/at-internet/piano-analytics-apple", .upToNextMajor(from: "3.1.0")),
    ],
    targets: [
        .target(
            name: "piano_analytics",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "PianoAnalytics", package: "piano-analytics-apple")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
