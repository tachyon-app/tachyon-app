// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tachyon",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Tachyon",
            targets: ["Tachyon"]
        )
    ],
    dependencies: [],
    targets: [
        // Main executable app
        .executableTarget(
            name: "Tachyon",
            dependencies: ["TachyonCore"],
            path: "Sources/Tachyon/App",
            resources: [
                .process("../../Resources")
            ]
        ),
        
        // Core library with all business logic
        .target(
            name: "TachyonCore",
            dependencies: [],
            path: "Sources/Tachyon",
            exclude: ["App"]
        ),
        
        // Tests
        .testTarget(
            name: "TachyonTests",
            dependencies: ["TachyonCore"],
            path: "Tests/TachyonTests"
        )
    ]
)
