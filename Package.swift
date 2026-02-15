// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CPUMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CPUMonitor", targets: ["CPUMonitor"])
    ],
    targets: [
        .executableTarget(
            name: "CPUMonitor",
            path: "Sources/CPUMonitor"
        )
    ]
)
