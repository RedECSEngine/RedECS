import XCTest
@testable import TiledInterpreter

final class TiledInterpreterTests: XCTestCase {

    var mapData: Data!
    var tileSetData: Data!

    func fixture(_ name: String) throws -> Data {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent(name)
        return try XCTUnwrap(FileManager.default.contents(atPath: path.path))
    }

    func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    override func setUpWithError() throws {
        mapData = try fixture("TestMap.tmj")
        tileSetData = try fixture("dungeon.tsj")
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
        XCTAssertEqual(tileSetInfo.textureId, "tiles_dungeon")
        XCTAssertEqual(tileSetInfo.tile(withLocalId: 0)?.class, "ground")
    }

    func testGroupedLayersFlattenInDocumentOrder() throws {
        let map = try JSONDecoder().decode(TiledMapJSON.self, from: try fixture("grouped-map.tmj"))

        XCTAssertEqual(map.layers.map(\.type), [.group, .group])
        XCTAssertEqual(map.tileLayers.map(\.name), ["Grass", "Ground", "Object", "Object 2"])
        XCTAssertEqual(map.width, 20)
        XCTAssertEqual(map.height, 30)
    }

    func testNestedGroupsFoldVisibilityOpacityAndOffsetIntoChildren() throws {
        let map = try decode(TiledMapJSON.self, from: """
        {"width":1,"height":1,"tilewidth":16,"tileheight":16,"tilesets":[],"layers":[
          {"id":1,"name":"outer","type":"group","visible":false,"opacity":0.5,"offsetx":10,"layers":[
            {"id":2,"name":"inner","type":"group","opacity":0.5,"offsety":4,"layers":[
              {"id":3,"name":"tiles","type":"tilelayer","width":1,"height":1,"data":[1]}
            ]}
          ]}
        ]}
        """)

        let layer = try XCTUnwrap(map.tileLayers.first)
        XCTAssertEqual(layer.name, "tiles")
        XCTAssertFalse(layer.visible)
        XCTAssertEqual(layer.opacity, 0.25)
        XCTAssertEqual(layer.offsetX, 10)
        XCTAssertEqual(layer.offsetY, 4)
    }

    func testGidsResolveToTheirOwnTilesetByFirstGid() throws {
        let map = try JSONDecoder()
            .decode(TiledMapJSON.self, from: try fixture("grouped-map.tmj"))
            .resolvingTileSets(from: [
                "Village_Tileset.tsj": try JSONDecoder()
                    .decode(TiledTilesetJSON.self, from: try fixture("Village_Tileset.tsj")),
                "AltRooves_Tileset.tsj": try JSONDecoder()
                    .decode(TiledTilesetJSON.self, from: try fixture("AltRooves_Tileset.tsj")),
            ])

        XCTAssertEqual(map.unresolvedTileSetSources, [])

        let firstOfVillage = try XCTUnwrap(map.tile(forGid: TiledGID(id: 1)))
        XCTAssertEqual(firstOfVillage.tileSet.name, "Village_Tileset")
        XCTAssertEqual(firstOfVillage.localId, 0)

        let lastOfVillage = try XCTUnwrap(map.tile(forGid: TiledGID(id: 1024)))
        XCTAssertEqual(lastOfVillage.tileSet.name, "Village_Tileset")
        XCTAssertEqual(lastOfVillage.localId, 1023)

        let firstOfRoofs = try XCTUnwrap(map.tile(forGid: TiledGID(id: 1025)))
        XCTAssertEqual(firstOfRoofs.tileSet.name, "AltRooves_Tileset")
        XCTAssertEqual(firstOfRoofs.localId, 0)

        XCTAssertNil(map.tile(forGid: .empty))
    }

    func testTilesetWithoutTileMetadataDecodes() throws {
        let tileSet = try JSONDecoder()
            .decode(TiledTilesetJSON.self, from: try fixture("AltRooves_Tileset.tsj"))
        XCTAssertEqual(tileSet.tiles, [])
        XCTAssertEqual(tileSet.columns, 30)
        XCTAssertEqual(tileSet.textureId, "AltRoofs_Tileset")
        XCTAssertFalse(tileSet.hasAnimatedTiles)
    }

    func testEmbeddedTilesetDecodesInline() throws {
        let map = try decode(TiledMapJSON.self, from: """
        {"width":1,"height":1,"tilewidth":16,"tileheight":16,"layers":[],"tilesets":[
          {"firstgid":1,"source":"external.tsj"},
          {"firstgid":9,"name":"inline","image":"extras.png","imagewidth":32,"imageheight":32,
           "tilewidth":16,"tileheight":16,"tilecount":4,"columns":2}
        ]}
        """)

        XCTAssertEqual(map.unresolvedTileSetSources, ["external.tsj"])
        XCTAssertEqual(map.tileSet(forGid: TiledGID(id: 9))?.name, "inline")
        XCTAssertEqual(map.tileSet(forGid: TiledGID(id: 9))?.textureId, "extras")
    }

    func testUnresolvedTilesetThrows() throws {
        let map = try decode(TiledMapJSON.self, from: """
        {"width":1,"height":1,"tilewidth":16,"tileheight":16,"layers":[],
         "tilesets":[{"firstgid":1,"source":"missing.tsj"}]}
        """)

        XCTAssertThrowsError(try map.resolvingTileSets(from: [:])) { error in
            XCTAssertEqual(error as? TiledError, .unresolvedTileSet(source: "missing.tsj"))
        }
    }

    func testFlipFlagsAreMaskedOutOfTheTileId() throws {
        let layer = try decode(TiledLayer.self, from: """
        {"id":1,"name":"flips","type":"tilelayer","width":4,"height":1,
         "data":[2147483651,1073741827,536870915,3]}
        """)

        let data = try XCTUnwrap(layer.data)
        XCTAssertEqual(data.map(\.id), [3, 3, 3, 3])
        XCTAssertEqual(data.map(\.isFlippedHorizontally), [true, false, false, false])
        XCTAssertEqual(data.map(\.isFlippedVertically), [false, true, false, false])
        XCTAssertEqual(data.map(\.isFlippedDiagonally), [false, false, true, false])
    }

    func testBase64LayerDataDecodes() throws {
        let layer = try decode(TiledLayer.self, from: """
        {"id":1,"name":"b64","type":"tilelayer","width":2,"height":2,
         "encoding":"base64","data":"AQAAAAIAAAADAAAABAAAAA=="}
        """)

        XCTAssertEqual(layer.data?.map(\.id), [1, 2, 3, 4])
        XCTAssertEqual(layer.tile(atColumn: 0, rowFromBottom: 0)?.id, 3)
    }

    func testCompressedLayerDataThrows() throws {
        XCTAssertThrowsError(try decode(TiledLayer.self, from: """
        {"id":1,"name":"z","type":"tilelayer","width":1,"height":1,
         "encoding":"base64","compression":"zlib","data":"eJw="}
        """)) { error in
            XCTAssertEqual(
                error as? TiledError,
                .compressedLayerDataUnsupported(layer: "z", compression: "zlib")
            )
        }
    }

    func testInfiniteMapChunksThrow() throws {
        XCTAssertThrowsError(try decode(TiledLayer.self, from: """
        {"id":1,"name":"inf","type":"tilelayer",
         "chunks":[{"x":0,"y":0,"width":1,"height":1,"data":[1]}]}
        """)) { error in
            XCTAssertEqual(error as? TiledError, .infiniteMapsUnsupported(layer: "inf"))
        }
    }

    func testLayerAccessorsAreBoundsCheckedOnNonSquareLayers() throws {
        let layer = TiledLayer(
            id: 1,
            name: "tall",
            type: .tileLayer,
            data: (0..<(20 * 30)).map { TiledGID(id: $0) },
            width: 20,
            height: 30
        )

        XCTAssertEqual(layer.tile(atColumn: 0, row: 0)?.id, 0)
        XCTAssertEqual(layer.tile(atColumn: 0, rowFromBottom: 0)?.id, 580)
        XCTAssertEqual(layer.tile(atColumn: 0, rowFromBottom: 29)?.id, 0)
        XCTAssertNil(layer.tile(atColumn: 0, rowFromBottom: 30))
        XCTAssertNil(layer.tile(atColumn: 20, row: 0))
        XCTAssertNil(layer.tile(atColumn: -1, row: 0))
        XCTAssertNil(layer.tile(atColumn: 0, row: 30))
    }

    func testShortLayerDataDoesNotTrap() throws {
        let layer = TiledLayer(
            id: 1,
            name: "short",
            type: .tileLayer,
            data: [TiledGID(id: 1)],
            width: 4,
            height: 4
        )
        XCTAssertEqual(layer.tile(atColumn: 0, row: 0)?.id, 1)
        XCTAssertNil(layer.tile(atColumn: 3, row: 3))
    }

    func testUnknownLayerTypesDoNotFailTheMap() throws {
        let map = try decode(TiledMapJSON.self, from: """
        {"width":1,"height":1,"tilewidth":16,"tileheight":16,"tilesets":[],"layers":[
          {"id":1,"name":"bg","type":"imagelayer","image":"bg.png"},
          {"id":2,"name":"future","type":"somethingnew"},
          {"id":3,"name":"tiles","type":"tilelayer","width":1,"height":1,"data":[1]}
        ]}
        """)

        XCTAssertEqual(map.layers.map(\.type), [.imageLayer, .unsupported("somethingnew"), .tileLayer])
        XCTAssertEqual(map.tileLayers.count, 1)
    }

    func testObjectShapesAndProperties() throws {
        let layer = try decode(TiledLayer.self, from: """
        {"id":1,"name":"objects","type":"objectgroup","objects":[
          {"id":1,"name":"spawn","class":"start","x":16,"y":32,"width":0,"height":0,
           "rotation":0,"visible":true,"point":true,
           "properties":[{"name":"party","type":"string","value":"fighter"},
                         {"name":"count","type":"int","value":3},
                         {"name":"tint","type":"color","value":"#ff0000"}]},
          {"id":2,"name":"area","x":0,"y":0,"width":32,"height":32,"rotation":0,"visible":true},
          {"id":3,"name":"prop","x":0,"y":0,"width":16,"height":16,"rotation":0,"visible":true,
           "gid":2147483653},
          {"id":4,"name":"zone","x":0,"y":0,"width":0,"height":0,"rotation":0,"visible":true,
           "polygon":[{"x":0,"y":0},{"x":16,"y":0},{"x":16,"y":16}]}
        ]}
        """)

        let objects = try XCTUnwrap(layer.objects)
        XCTAssertEqual(objects[0].shape, .point)
        XCTAssertEqual(objects[0].type, "start")
        XCTAssertEqual(objects[0][property: "party"]?.stringValue, "fighter")
        XCTAssertEqual(objects[0][property: "count"]?.intValue, 3)
        XCTAssertEqual(objects[0][property: "tint"]?.stringValue, "#ff0000")
        XCTAssertEqual(objects[1].shape, .rectangle)
        XCTAssertEqual(objects[2].gid?.id, 5)
        XCTAssertEqual(objects[2].gid?.isFlippedHorizontally, true)
        XCTAssertEqual(objects[3].shape, .polygon([
            TiledPoint(x: 0, y: 0), TiledPoint(x: 16, y: 0), TiledPoint(x: 16, y: 16),
        ]))
    }

    func testTileAnimationAndCollisionShapesDecode() throws {
        let tileSet = try decode(TiledTilesetJSON.self, from: """
        {"name":"animated","image":"water.png","imagewidth":32,"imageheight":32,
         "tilewidth":16,"tileheight":16,"tilecount":4,"columns":2,"tiles":[
           {"id":0,"animation":[{"duration":100,"tileid":0},{"duration":100,"tileid":1}]},
           {"id":2,"objectgroup":{"id":2,"name":"","type":"objectgroup","objects":[
             {"id":1,"name":"","x":0,"y":8,"width":16,"height":8,"rotation":0,"visible":true}
           ]}}
         ]}
        """)

        XCTAssertTrue(tileSet.hasAnimatedTiles)
        let animated = try XCTUnwrap(tileSet.tile(withLocalId: 0))
        XCTAssertEqual(animated.animationDuration, 200)
        XCTAssertEqual(animated.animationFrame(atMilliseconds: 0)?.tileId, 0)
        XCTAssertEqual(animated.animationFrame(atMilliseconds: 150)?.tileId, 1)
        XCTAssertEqual(animated.animationFrame(atMilliseconds: 250)?.tileId, 0)

        let collider = try XCTUnwrap(tileSet.tile(withLocalId: 2))
        XCTAssertEqual(collider.objectGroup?.objects?.count, 1)
        XCTAssertEqual(collider.objectGroup?.objects?.first?.height, 8)
    }

    func testMapRoundTripsThroughCoding() throws {
        let map = try JSONDecoder().decode(TiledMapJSON.self, from: try fixture("grouped-map.tmj"))
        let encoded = try JSONEncoder().encode(map)
        XCTAssertEqual(try JSONDecoder().decode(TiledMapJSON.self, from: encoded), map)
    }
}
