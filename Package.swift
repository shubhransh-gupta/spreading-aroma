// swift-tools-version: 6.2
import PackageDescription
import Foundation

// The SpreadingAromaApp executable requires Xcode (SwiftUI macros).
// Include it only when building from Xcode or when explicitly requested.
let includeApp = ProcessInfo.processInfo.environment["INCLUDE_APP"] != nil
    || ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil

var products: [Product] = [
    .library(name: "XibConverterCore", targets: ["XibConverterCore"]),
]
var targets: [Target] = [
    .target(name: "XibConverterCore"),
    .testTarget(
        name: "XibConverterCoreTests",
        dependencies: ["XibConverterCore"]
    ),
]

if includeApp {
    products.append(.executable(name: "SpreadingAromaApp", targets: ["SpreadingAromaApp"]))
    targets.append(.executableTarget(
        name: "SpreadingAromaApp",
        dependencies: ["XibConverterCore"]
    ))
}

let package = Package(
    name: "SpreadingAroma",
    platforms: [.macOS(.v15)],
    products: products,
    targets: targets
)
