// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pipsey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "PipseyCore", targets: ["PipseyCore"]),
        .executable(name: "Pipsey", targets: ["Pipsey"]),
        .executable(name: "PipseyTests", targets: ["PipseyTests"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PipseyCore",
            dependencies: [],
            path: "Sources/PipseyCore"
        ),
        .executableTarget(
            name: "Pipsey",
            dependencies: ["PipseyCore"],
            path: "Sources/Pipsey"
        ),
        .executableTarget(
            name: "PipseyTests",
            dependencies: ["PipseyCore"],
            path: "Sources/PipseyTests"
        ),
    ]
)
