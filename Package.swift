// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SpreadingAroma",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "XibConverterCore", targets: ["XibConverterCore"]),
        .executable(name: "SpreadingAromaApp", targets: ["SpreadingAromaApp"]),
    ],
    targets: [
        .target(name: "XibConverterCore"),
        .executableTarget(
            name: "SpreadingAromaApp",
            dependencies: ["XibConverterCore"]
        ),
        .testTarget(
            name: "XibConverterCoreTests",
            dependencies: ["XibConverterCore"]
        ),
    ]
)
