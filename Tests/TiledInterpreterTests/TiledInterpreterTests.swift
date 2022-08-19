import XCTest
@testable import TiledInterpreter
import SpriteKit
import SnapshotTesting
//import XMLCoder

enum TestTiledObjectType: String {
    case enemy
    case start
    case door
    case chest
    case unknown = ""
}

final class TiledInterpreterTests: XCTestCase {
    
    var mapData: Data!
    var tileMapImageData: Data!
    var tileSetData: Data!
    
    override func setUpWithError() throws {
        let mapDataPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("TestMap.json")
        
        let tilesFilePath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("tiles_dungeon.png")
        
        let tileSetFilePath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("dungeon.tsx")
        
        guard let mapData = FileManager.default.contents(atPath: mapDataPath.path),
              let tilesData = FileManager.default.contents(atPath: tilesFilePath.path),
              let tileSetData = FileManager.default.contents(atPath: tileSetFilePath.path) else {
            XCTFail()
            return
        }
        
        self.mapData = mapData
        self.tileMapImageData = tilesData
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
    
    func testSplittingImage() {
        let dict = makeImageTileDictionary(name: "dungeon", imageData: tileMapImageData, tileWidth: 16, tileHeight: 16)
        XCTAssertEqual(dict?.count, 380)
        
        let atlas = makeTextureAtlas(name: "dungeon", imageData: tileMapImageData, tileWidth: 16, tileHeight: 16)
        XCTAssertEqual(atlas?.textureNames.count, 380)
        
        let tileset = makeTileset(name: "dungeon", imageData: tileMapImageData, tileWidth: 16, tileHeight: 16)
        XCTAssertEqual(tileset?.tileGroups.count, 380)
        XCTAssertEqual(tileset?.defaultTileSize, .init(width: 16, height: 16))
        XCTAssertEqual(tileset?.name, "dungeon")
    }
    
    func testTileSetDataInterpreter() throws {
        let tileSetInfo = try XMLDecoder().decode(TiledTilesetXML.self, from: tileSetData)
        XCTAssertEqual(tileSetInfo.name, "dungeon")
        XCTAssertEqual(tileSetInfo.tiles?.count, 2)
    }
    
    func testMapGeneration() throws {
        let tiledMap = try TiledMap(
            mapData: mapData,
            tileSetImageData: tileMapImageData,
            tileSetData: tileSetData
        )
        assertSnapshot(matching: try tiledMap.createScene(), as: .image, record: false)
    }
    
}

extension Snapshotting where Value == SKScene, Format == NSImage {
    static var image: Snapshotting {
        return Snapshotting<NSView, NSImage>.image.pullback { scene in
            let view = SKView(frame: .init(origin: .zero, size: scene.size))
            view.presentScene(scene)
            return view
        }
    }
}

extension Snapshotting where Value == SKNode, Format == NSImage {
    static func image(sceneSize: CGSize) -> Snapshotting {
        return Snapshotting<SKScene, NSImage>.image.pullback { node in
            let scene = SKScene(size: sceneSize)
            node.position = .init(x: sceneSize.width/2, y: sceneSize.height/2)
            scene.addChild(node)
            return scene
        }
    }
}
