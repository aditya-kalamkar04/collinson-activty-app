// swift-tools-version: 6.0
import PackageDescription

// Everything that isn't SwiftUI lives here so it can be tested with `swift test`
// in a few seconds, without booting a simulator.
let package = Package(
    name: "ActivityForecastKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ActivityForecastKit", targets: ["ActivityForecastKit"])
    ],
    targets: [
        .target(name: "ActivityForecastKit")
    ]
)
