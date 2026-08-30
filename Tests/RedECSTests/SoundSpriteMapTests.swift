import XCTest
import Foundation
import RedECS

final class SoundSpriteMapTests: XCTestCase {
    func testDecodesTwoElementSegments() throws {
        let json = #"{"src":["sfx.m4a"],"sprite":{"blip-high":[0,200],"thud":[1000,300]}}"#
        let map = try JSONDecoder().decode(SoundSpriteMap.self, from: Data(json.utf8))
        XCTAssertEqual(map.src, ["sfx.m4a"])
        XCTAssertEqual(map.sprite["blip-high"], .init(offsetMs: 0, durationMs: 200))
        XCTAssertEqual(map.sprite["thud"], .init(offsetMs: 1000, durationMs: 300))
        XCTAssertEqual(map.sprite["thud"]?.loops, false)
    }

    func testDecodesThreeElementLoopingSegments() throws {
        let json = #"{"src":["music.m4a"],"sprite":{"theme":[0,20000,true]}}"#
        let map = try JSONDecoder().decode(SoundSpriteMap.self, from: Data(json.utf8))
        XCTAssertEqual(map.sprite["theme"], .init(offsetMs: 0, durationMs: 20000, loops: true))
    }

    func testRoundTripsThroughCodable() throws {
        let map = SoundSpriteMap(
            src: ["sfx.m4a"],
            sprite: [
                "blip": .init(offsetMs: 0, durationMs: 450),
                "theme": .init(offsetMs: 750, durationMs: 1200, loops: true),
            ]
        )
        let data = try JSONEncoder().encode(map)
        let decoded = try JSONDecoder().decode(SoundSpriteMap.self, from: data)
        XCTAssertEqual(decoded, map)
    }

    func testNonLoopingSegmentsEncodeAsTwoElementArrays() throws {
        let data = try JSONEncoder().encode(SoundSpriteMap.Segment(offsetMs: 10, durationMs: 20))
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "[10,20]")
    }

    func testRejectsASegmentMissingItsDuration() {
        let json = #"{"src":["sfx.m4a"],"sprite":{"blip":[0]}}"#
        XCTAssertThrowsError(try JSONDecoder().decode(SoundSpriteMap.self, from: Data(json.utf8)))
    }

    func testRejectsNonNumericSegments() {
        let json = #"{"src":["sfx.m4a"],"sprite":{"blip":["0","450"]}}"#
        XCTAssertThrowsError(try JSONDecoder().decode(SoundSpriteMap.self, from: Data(json.utf8)))
    }

    func testSoundIdEncodesAsABareString() throws {
        let id: SoundId = "blip-high"
        let data = try JSONEncoder().encode([id])
        XCTAssertEqual(String(decoding: data, as: UTF8.self), #"["blip-high"]"#)
        XCTAssertEqual(try JSONDecoder().decode([SoundId].self, from: data), [id])
    }
}
