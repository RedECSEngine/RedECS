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
        .library(
            name: "RedECS",
            targets: ["RedECS"]
        ),
        .library(
            name: "RedECSAppleSupport",
            targets: ["RedECSAppleSupport"]
        ),
        .library(
            name: "RedECSBasicComponents",
            targets: ["RedECSBasicComponents"]
        ),
        .library(
            name: "RedECSRenderingComponents",
            targets: ["RedECSRenderingComponents"]
        ),
        .library(
            name: "RedECSSpriteKitSupport",
            targets: ["RedECSSpriteKitSupport"]
        ),
        .library(
            name: "RedECSWebSupport",
            targets: ["RedECSWebSupport"]
        ),
        .library(
            name: "RedECSExamples",
            targets: ["RedECSExamples"]
        ),
        .library(
            name: "TiledInterpreter",
            targets: ["TiledInterpreter"]
        ),
        .library(
            name: "TiledSpriteKitSupport",
            targets: ["TiledSpriteKitSupport"]
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
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.13.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RedECS",
            dependencies: [
                "TiledInterpreter",
                .product(
                    name: "Geometry",
                    package: "Geometry"
                ),
                .product(
                    name: "GeometryAlgorithms",
                    package: "Geometry"
                )
            ]
        ),
        .testTarget(
            name: "RedECSTests",
            dependencies: ["RedECS", "RedECSBasicComponents", "RedECSAppleSupport"]
        ),
        .testTarget(
            name: "RenderingTests",
            dependencies: [
                "RedECS",
                "RedECSRenderingComponents",
                "RedECSAppleSupport",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        
        .target(
            name: "RedECSAppleSupport",
            dependencies: [
                "RedECS"
            ]
        ),
        
        .target(
            name: "RedECSBasicComponents",
            dependencies: ["RedECS"]
        ),
        
        .target(
            name: "RedECSRenderingComponents",
            dependencies: [
                "RedECS",
                "RedECSBasicComponents"
            ]
        ),
        
        .target(
            name: "RedECSSpriteKitSupport",
            dependencies: [
                "RedECSRenderingComponents",
                .product(
                    name: "GeometrySpriteKitExtensions",
                    package: "Geometry"
                )
            ]
        ),
        
        .target(
            name: "RedECSWebSupport",
            dependencies: [
                "RedECSRenderingComponents",
                .product(name: "JavaScriptKit", package: "JavaScriptKit")
            ]
        ),
        
        .target(
            name: "RedECSExamples",
            dependencies: ["RedECSRenderingComponents", "RedECSSpriteKitSupport"]
        ),
        
        .target(
            name: "TiledInterpreter",
            dependencies: []
        ),
        
        .target(
            name: "TiledSpriteKitSupport",
            dependencies: ["TiledInterpreter", "XMLCoder"]
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
