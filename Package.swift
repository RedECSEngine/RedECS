// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RedECS",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .tvOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
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
            name: "JavaScriptKit",
            url: "https://github.com/swiftwasm/JavaScriptKit",
            from: "0.13.0"
        ),
//        .package(
//            url: "git@github.com:RedECSEngine/Geometry.git",
//            from: "0.0.3"
//        ),
//        .package(path: "../Geometry"),
        .package(url: "git@github.com:RedECSEngine/Geometry.git", .branch("develop")),
        
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0"),
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
            dependencies: ["RedECSKit"]
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
            ]
        ),
        .testTarget(
            name: "TiledInterpreterTests",
            dependencies: [
                "TiledInterpreter",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
    ]
)
