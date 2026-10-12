
 // swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "device_diagnostics",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "device-diagnostics",
            targets: ["device_diagnostics"]
        )
    ],
    dependencies: [
        .package(
            name: "FlutterFramework",
            path: "../FlutterFramework"
        )
    ],
    targets: [
        .target(
            name: "device_diagnostics",
            dependencies: [
                .product(
                    name: "FlutterFramework",
                    package: "FlutterFramework"
                )
            ]
        )
    ]
)
