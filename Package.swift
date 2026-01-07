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
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0")
    ],
    targets: [
        // Main executable app
        .executableTarget(
            name: "Tachyon",
            dependencies: ["TachyonCore"],
            path: "Sources/Tachyon/App"
        ),
        
        // Core library with all business logic
        .target(
            name: "TachyonCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/Tachyon",
            exclude: ["App"],
            resources: [
                .process("Resources")
            ]
        ),
        
        // Tests
        .testTarget(
            name: "TachyonTests",
            dependencies: ["TachyonCore"],
            path: "Tests/TachyonTests"
        )
    ]
)
