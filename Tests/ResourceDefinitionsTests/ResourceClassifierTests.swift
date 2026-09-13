import XCTest
@testable import ResourceDefinitionsCore

final class ResourceClassifierTests: XCTestCase {
    func testClassifiesAGameResourceFolder() {
        let classification = ResourceClassifier.classify(paths: [
            ".DS_Store",
            "Media.xcassets/Contents.json",
            "Media.xcassets/pt-mono.imageset/pt-mono.png",
            "MissionControl.tmj",
            "Overworld.tmx",
            "OverworldTileset.tsx",
            "RPData.json",
            "item.csv",
            "main.tsj",
            "pt-mono.fnt",
            "pt-mono.png",
            "skeleton.boss.json",
            "skeleton.boss.png",
            "sounds.json",
            "sounds.m4a",
            "tiles-main.png",
            "weapons.json",
            "weapons.png",
        ])

        XCTAssertEqual(classification.diagnostics, [])
        XCTAssertEqual(classification.catalog.entries(in: .images), [
            ResourceEntry(identifier: "skeletonBoss", name: "skeleton.boss", ext: "png"),
            ResourceEntry(identifier: "weapons", name: "weapons", ext: "png"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .fonts), [
            ResourceEntry(identifier: "ptMono", name: "pt-mono", ext: "fnt"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .tileMaps), [
            ResourceEntry(identifier: "missionControl", name: "MissionControl", ext: "tmj"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .tileSets), [
            ResourceEntry(identifier: "main", name: "main", ext: "tsj"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .json), [
            ResourceEntry(identifier: "rpData", name: "RPData", ext: "json"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .csv), [
            ResourceEntry(identifier: "item", name: "item", ext: "csv"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .sounds), [
            ResourceEntry(identifier: "sounds", name: "sounds", ext: "json"),
        ])
    }

    func testJPEGAtlasIsAnImage() {
        let classification = ResourceClassifier.classify(paths: ["photo.jpg", "photo.json"])

        XCTAssertEqual(classification.catalog.entries(in: .images), [
            ResourceEntry(identifier: "photo", name: "photo", ext: "jpg"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .json), [])
    }

    func testIdentifierCollisionIsAnError() {
        let classification = ResourceClassifier.classify(paths: ["level-1.tmj", "level_1.tmj"])

        XCTAssertTrue(classification.hasErrors)
        XCTAssertEqual(classification.diagnostics, [
            .error("'level-1.tmj' and 'level_1.tmj' both generate 'TileMaps.level1'; rename one of them"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .tileMaps).map(\.name), ["level-1"])
    }

    func testReservedIdentifierIsAnError() {
        let classification = ResourceClassifier.classify(paths: ["all.csv"])

        XCTAssertEqual(classification.diagnostics, [
            .error("'all.csv' would generate 'CSV.all', which is reserved; rename the file"),
        ])
    }

    func testFileWithoutIdentifierCharactersIsAnError() {
        let classification = ResourceClassifier.classify(paths: ["---.csv"])

        XCTAssertEqual(classification.diagnostics, [
            .error("'---.csv' has no characters usable in a Swift identifier"),
        ])
    }

    func testSubdirectoriesAreWarnedOnceAndSkipped() {
        let classification = ResourceClassifier.classify(paths: ["levels/a.tmj", "levels/b.tmj", "top.tmj"])

        XCTAssertEqual(classification.diagnostics, [
            .warning("resources in subdirectory 'levels' are not included in resource definitions; move them to the top level of the resource folder"),
        ])
        XCTAssertEqual(classification.catalog.entries(in: .tileMaps).map(\.name), ["top"])
    }

    func testIdentifierConversion() {
        XCTAssertEqual(SwiftIdentifier.make(from: "chara_goblin_sniper"), "charaGoblinSniper")
        XCTAssertEqual(SwiftIdentifier.make(from: "skeleton.boss"), "skeletonBoss")
        XCTAssertEqual(SwiftIdentifier.make(from: "level-1"), "level1")
        XCTAssertEqual(SwiftIdentifier.make(from: "MissionControl"), "missionControl")
        XCTAssertEqual(SwiftIdentifier.make(from: "RPData"), "rpData")
        XCTAssertEqual(SwiftIdentifier.make(from: "UI"), "ui")
        XCTAssertEqual(SwiftIdentifier.make(from: "Village Map"), "villageMap")
        XCTAssertEqual(SwiftIdentifier.make(from: "8bit-font"), "_8bitFont")
        XCTAssertNil(SwiftIdentifier.make(from: "--"))
    }

    func testKeywordIdentifiersAreEscaped() {
        XCTAssertEqual(SwiftIdentifier.escaped("default"), "`default`")
        XCTAssertEqual(SwiftIdentifier.escaped("weapons"), "weapons")
    }
}
