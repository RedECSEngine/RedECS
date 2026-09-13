import XCTest
@testable import ResourceDefinitionsCore

final class ResourceDefinitionsRendererTests: XCTestCase {
    func testRendersEveryGroupWithPreloadableAggregate() {
        let catalog = ResourceClassifier.classify(paths: [
            "default.tmj",
            "hud-sprite.json",
            "hud-sprite.png",
            "sounds.json",
            "sounds.m4a",
        ]).catalog

        let source = ResourceDefinitionsRenderer.render(catalog, typeName: "GameResources", accessLevel: .public)

        XCTAssertEqual(source, """
        import RedECS

        public enum GameResources {
            public enum Images {
                public static let hudSprite = LoadableResource(name: "hud-sprite", ext: "png", type: .image)

                public static let all: [LoadableResource] = [
                    hudSprite,
                ]
            }

            public enum Fonts {
                public static let all: [LoadableResource] = []
            }

            public enum TileMaps {
                public static let `default` = LoadableResource(name: "default", ext: "tmj", type: .tilemap)

                public static let all: [LoadableResource] = [
                    `default`,
                ]
            }

            public enum TileSets {
                public static let all: [LoadableResource] = []
            }

            public enum JSON {
                public static let all: [LoadableResource] = []
            }

            public enum CSV {
                public static let all: [LoadableResource] = []
            }

            public enum Sounds {
                public static let sounds = LoadableResource(name: "sounds", ext: "json", type: .soundSprite)

                public static let all: [LoadableResource] = [
                    sounds,
                ]
            }

            public static let all: [LoadableResource] = [
                Images.all,
                Fonts.all,
                TileMaps.all,
                TileSets.all,
                JSON.all,
                CSV.all,
            ].flatMap { $0 }
        }

        """)
    }

    func testEscapesStringLiterals() {
        let catalog = ResourceClassifier.classify(paths: ["say \"hi\".csv"]).catalog

        let source = ResourceDefinitionsRenderer.render(catalog, typeName: "Resources", accessLevel: .internal)

        XCTAssertTrue(source.contains(#"internal static let sayHi = LoadableResource(name: "say \"hi\"", ext: "csv", type: .csv)"#))
    }

    func testTypeNameValidation() {
        XCTAssertTrue(ResourceDefinitionsRenderer.isValidTypeName("Resources"))
        XCTAssertTrue(ResourceDefinitionsRenderer.isValidTypeName("_Assets2"))
        XCTAssertFalse(ResourceDefinitionsRenderer.isValidTypeName("2Assets"))
        XCTAssertFalse(ResourceDefinitionsRenderer.isValidTypeName("My-Resources"))
        XCTAssertFalse(ResourceDefinitionsRenderer.isValidTypeName("class"))
    }
}
