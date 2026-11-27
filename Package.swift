// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "XibToSwiftUI",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "XibConverterCore", targets: ["XibConverterCore"]),
        .executable(name: "XibToSwiftUIApp", targets: ["XibToSwiftUIApp"]),
    ],
    targets: [
        .target(name: "XibConverterCore"),
        .executableTarget(
            name: "XibToSwiftUIApp",
            dependencies: ["XibConverterCore"]
        ),
        .testTarget(
            name: "XibConverterCoreTests",
            dependencies: ["XibConverterCore"]
        ),
    ]
)
