// swift-tools-version:6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "RedECS",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
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
            name: "RedHUD",
            targets: ["RedHUD"]
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

        .library(
            name: "CSVInterpreter",
            targets: ["CSVInterpreter"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftwasm/JavaScriptKit",
            from: "0.56.0"
        ),
        .package(
            url: "https://github.com/RedECSEngine/Geometry.git",
            from: "0.0.7"
        ),

        .package(
            url: "https://github.com/RedECSEngine/Randomization.git",
            exact: "0.0.1"
        ),

        .package(
            url: "https://github.com/apple/swift-collections.git",
            from: "1.1.0"
        ),

        .package(
            url: "https://github.com/RedECSEngine/Graphs.git",
            from: "0.1.0"
        ),

        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.0"),

        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"700.0.0"),
    ],
    targets: [
        .target(
            name: "RedECSKit",
            dependencies: [
                "RedECS",
                "RedECSBasicComponents",
                "RedHUD"
            ]
        ),

        .target(
            name: "RedECS",
            dependencies: [
                .product(name: "Geometry", package: "Geometry"),
                .product(name: "GeometryAlgorithms", package: "Geometry"),
                .product(name: "Randomization", package: "Randomization"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Graphs", package: "Graphs"),
                "TiledInterpreter",
                "RedECSMacros",
            ]
        ),

        .macro(
            name: "RedECSMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "RedECSBasicComponents",
            dependencies: ["RedECS"]
        ),
        .target(
            name: "RedHUD",
            dependencies: ["RedECS", "TiledInterpreter"]
        ),

        .target(
            name: "RedECSAppleSupport",
            dependencies: ["RedECSKit", "CSVInterpreter"]
        ),
        .target(
            name: "RedECSWebSupport",
            dependencies: [
                "RedECSKit",
                "CSVInterpreter",
                .product(name: "JavaScriptKit", package: "JavaScriptKit")
            ]
        ),

        .target(
            name: "TiledInterpreter",
            dependencies: []
        ),

        .target(
            name: "CSVInterpreter",
            dependencies: []
        ),

        .testTarget(
            name: "RedECSTests",
            dependencies: ["RedECS", "RedECSBasicComponents", "RedECSAppleSupport"]
        ),
        .testTarget(
            name: "RedHUDTests",
            dependencies: ["RedHUD"]
        ),
        .testTarget(
            name: "RedECSMacrosTests",
            dependencies: [
                "RedECSMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "RenderingTests",
            dependencies: [
                "RedECS",
                "RedECSAppleSupport",
                "RedHUD",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            exclude: ["__Snapshots__"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CSVInterpreterTests",
            dependencies: ["CSVInterpreter"]
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
                "grouped-map.tmj",
                "Village_Tileset.tsj",
                "AltRooves_Tileset.tsj",
            ]
        ),
    ]
)
