import XCTest
@testable import TiledInterpreter

final class TiledInterpreterTests: XCTestCase {

    var mapData: Data!
    var tileSetData: Data!

    override func setUpWithError() throws {
        let mapDataPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestMap.tmj")

        let tileSetFilePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("dungeon.tsj")

        guard let mapData = FileManager.default.contents(atPath: mapDataPath.path),
              let tileSetData = FileManager.default.contents(atPath: tileSetFilePath.path) else {
            XCTFail()
            return
        }

        self.mapData = mapData
        self.tileSetData = tileSetData
    }

    func testLoadingJSON() throws {
        let map = try JSONDecoder().decode(TiledMapJSON.self, from: mapData)

        XCTAssertEqual(map.layers.count, 3)
        XCTAssertEqual(map.layers.first?.type, .tileLayer)
        XCTAssertEqual(map.layers.last?.type, .objectGroup)
        XCTAssertEqual(map.layers.last?.objects?.first?.type, "")
        XCTAssertEqual(map.layers.last?.objects?[1].type, "start")
    }

    func testTileSetDataInterpreter() throws {
        let tileSetInfo = try JSONDecoder().decode(TiledTilesetJSON.self, from: tileSetData)
        XCTAssertEqual(tileSetInfo.name, "dungeon")
        XCTAssertEqual(tileSetInfo.tileCount, 380)

        let tileInfo = tileSetInfo.makeTileInfoDictionary()
        XCTAssertFalse(tileInfo.isEmpty)
    }

}
