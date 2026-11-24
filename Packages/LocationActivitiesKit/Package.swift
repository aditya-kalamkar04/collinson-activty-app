// swift-tools-version: 6.0
import PackageDescription

// Everything that isn't SwiftUI lives here so it can be tested with `swift test`
// in a few seconds, without booting a simulator.
let package = Package(
    name: "LocationActivitiesKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LocationActivitiesKit", targets: ["LocationActivitiesKit"])
    ],
    targets: [
        .target(name: "LocationActivitiesKit"),
        .testTarget(
            name: "LocationActivitiesKitTests",
            dependencies: ["LocationActivitiesKit"]
        )
    ]
)
