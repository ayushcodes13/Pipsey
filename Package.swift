// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pipsey",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "NotchKit", targets: ["NotchKit"]),
        .library(name: "PipseyCore", targets: ["PipseyCore"]),
        .executable(name: "Pipsey", targets: ["Pipsey"]),
        .executable(name: "PipseyTests", targets: ["PipseyTests"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NotchKit",
            path: "Sources/NotchKit"
        ),
        .target(
            name: "PipseyCore",
            dependencies: ["NotchKit"],
            path: "Sources/PipseyCore"
        ),
        .executableTarget(
            name: "Pipsey",
            dependencies: ["PipseyCore", "NotchKit"],
            path: "Sources/Pipsey"
        ),
        .executableTarget(
            name: "PipseyTests",
            dependencies: ["PipseyCore", "NotchKit"],
            path: "Sources/PipseyTests"
        ),
    ]
)
