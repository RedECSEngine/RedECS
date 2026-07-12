// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "RedECS",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16)
    ],
    products: [
        .library(name: "RedECSKit", targets: ["RedECSKit"]),
        .library(
            name: "RedECS",
            targets: ["RedECS"]
        ),
        .library(
            name: "RedECSBasicComponents",
            targets: ["RedECSBasicComponents"]
        ),
        .library(
            name: "RedECSUIComponents",
            targets: ["RedECSUIComponents"]
        ),

        .library(
            name: "RedECSAppleSupport",
            targets: ["RedECSAppleSupport"]
        ),
        .library(
            name: "RedECSWebSupport",
            targets: ["RedECSWebSupport"]
        ),

        .library(
            name: "TiledInterpreter",
            targets: ["TiledInterpreter"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftwasm/JavaScriptKit",
            from: "0.56.0"
        ),
        .package(
            url: "https://github.com/RedECSEngine/Geometry.git",
            from: "0.0.5"
        ),

        .package(
            url: "https://github.com/apple/swift-collections.git",
            from: "1.1.0"
        ),

        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.0"),
    ],
    targets: [
        .target(
            name: "RedECSKit",
            dependencies: [
                "RedECS",
                "RedECSBasicComponents",
                "RedECSUIComponents"
            ]
        ),

        .target(
            name: "RedECS",
            dependencies: [
                .product(name: "Geometry", package: "Geometry"),
                .product(name: "GeometryAlgorithms", package: "Geometry"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                "TiledInterpreter",
            ]
        ),
        .target(
            name: "RedECSBasicComponents",
            dependencies: ["RedECS"]
        ),
        .target(
            name: "RedECSUIComponents",
            dependencies: ["RedECS", "RedECSBasicComponents"]
        ),

        .target(
            name: "RedECSAppleSupport",
            dependencies: ["RedECSKit"],
            resources: [
                .process("Shaders.metal")
            ]
        ),
        .target(
            name: "RedECSWebSupport",
            dependencies: [
                "RedECSKit",
                .product(name: "JavaScriptKit", package: "JavaScriptKit")
            ]
        ),

        .target(
            name: "TiledInterpreter",
            dependencies: []
        ),

        .testTarget(
            name: "RedECSTests",
            dependencies: ["RedECS", "RedECSBasicComponents", "RedECSAppleSupport"]
        ),
        .testTarget(
            name: "RenderingTests",
            dependencies: [
                "RedECS",
                "RedECSAppleSupport",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            exclude: ["__Snapshots__"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TiledInterpreterTests",
            dependencies: [
                "TiledInterpreter",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            exclude: [
                "TestMap.tmj",
                "TestMap.png",
                "dungeon.tsj",
                "tiles_dungeon.png",
            ]
        ),
    ]
)
