import XCTest
import Geometry
import GeometryAlgorithms
import TiledInterpreter
@testable import RedECS

final class TileMapRenderingTests: XCTestCase {

    final class StubResourceManager: ResourceManager {
        var textures: [TextureId: Resource<TextureMap>] = [:]
        var animations: [TextureId: SpriteAnimationDictionary] = [:]
        var tileMaps: [String: TiledMapJSON] = [:]
        var tileSets: [String: TiledTilesetJSON] = [:]
        var fonts: [String: BitmapFont] = [:]
        func preload(_ assets: [LoadableResource]) -> Future<Void, Error> { .just(()) }
        func startTextureLoadIfNeeded(textureId: TextureId) -> Future<Void, Error> { .just(()) }
        func loadJSONFile<T: Decodable>(_ name: String, decodedAs: T.Type) -> Future<T, Error> { Future { _ in } }
        func loadTiledMap(_ name: String) -> Future<TiledMapJSON, Error> { Future { _ in } }
        func loadBitmapFontTextFile(_ name: String) -> Future<BitmapFont, Error> { Future { _ in } }
    }

    func tileSet(
        name: String,
        image: String,
        columns: Int,
        rows: Int,
        tileSize: Int = 16,
        margin: Int = 0,
        spacing: Int = 0,
        tiles: [TiledTile] = []
    ) -> TiledTilesetJSON {
        TiledTilesetJSON(
            name: name,
            image: image,
            imageWidth: margin * 2 + columns * tileSize + (columns - 1) * spacing,
            imageHeight: margin * 2 + rows * tileSize + (rows - 1) * spacing,
            tileWidth: tileSize,
            tileHeight: tileSize,
            tileCount: columns * rows,
            columns: columns,
            margin: margin,
            spacing: spacing,
            tiles: tiles
        )
    }

    func map(
        gids: [[Int]],
        tileSets: [TiledTilesetReference],
        opacity: Double = 1,
        visible: Bool = true
    ) -> TiledMapJSON {
        let height = gids.count
        let width = gids.first?.count ?? 0
        return TiledMapJSON(
            tileWidth: 16,
            tileHeight: 16,
            width: width,
            height: height,
            layers: [
                TiledLayer(
                    id: 1,
                    name: "tiles",
                    type: .tileLayer,
                    data: gids.flatMap { $0.map { TiledGID(rawValue: UInt32($0)) } },
                    opacity: opacity,
                    visible: visible,
                    width: width,
                    height: height
                )
            ],
            tileSets: tileSets
        )
    }

    func renderGroups(
        _ map: TiledMapJSON,
        at position: Point = .zero,
        cameraCenter: Point = .zero,
        cameraSize: Size = Size(width: 320, height: 320),
        animationTime: Double = 0
    ) -> [RenderGroup] {
        var sprite = SpriteComponent(entity: "map", type: .tileMap(map), anchorPoint: .zero)
        sprite.tileAnimationTime = animationTime
        return sprite.renderGroups(
            cameraMatrix: .projection(rect: Rect(center: cameraCenter, size: cameraSize)),
            transform: TransformComponent(entity: "map", position: position),
            resourceManager: StubResourceManager()
        )
    }

    func textureBounds(of group: RenderGroup) -> Rect {
        let points = group.triangles.compactMap(\.textureTriangle)
            .flatMap { [$0.a, $0.b, $0.c] }
        let xs = points.map(\.x), ys = points.map(\.y)
        return Rect(
            x: xs.min()!,
            y: ys.min()!,
            width: xs.max()! - xs.min()!,
            height: ys.max()! - ys.min()!
        )
    }

    func vertexBounds(of group: RenderGroup) -> Rect {
        let points = group.triangles.flatMap { [$0.triangle.a, $0.triangle.b, $0.triangle.c] }
        let xs = points.map(\.x), ys = points.map(\.y)
        return Rect(
            x: xs.min()!,
            y: ys.min()!,
            width: xs.max()! - xs.min()!,
            height: ys.max()! - ys.min()!
        )
    }

    func testLastTileOfATilesetRowSamplesItsOwnRegion() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 4, rows: 2)
        let groups = renderGroups(map(
            gids: [[4]],
            tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]
        ))

        let group = try XCTUnwrap(groups.first)
        XCTAssertEqual(group.textureId, "sheet")
        XCTAssertEqual(textureBounds(of: group), Rect(x: 48, y: 16, width: 16, height: 16))
    }

    func testFirstTileOfTheNextRowSamplesTheNextRow() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 4, rows: 2)
        let groups = renderGroups(map(
            gids: [[5]],
            tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]
        ))

        XCTAssertEqual(textureBounds(of: try XCTUnwrap(groups.first)), Rect(x: 0, y: 0, width: 16, height: 16))
    }

    func testEachTilesetDrawsFromItsOwnTextureRebasedByFirstGid() throws {
        let first = tileSet(name: "first", image: "first.png", columns: 4, rows: 1)
        let second = tileSet(name: "second", image: "second.png", columns: 4, rows: 1)
        let groups = renderGroups(map(
            gids: [[1, 5]],
            tileSets: [
                TiledTilesetReference(firstGid: 1, tileSet: first),
                TiledTilesetReference(firstGid: 5, tileSet: second),
            ]
        ))

        XCTAssertEqual(groups.map(\.textureId), ["first", "second"])
        XCTAssertEqual(textureBounds(of: groups[0]), Rect(x: 0, y: 0, width: 16, height: 16))
        XCTAssertEqual(textureBounds(of: groups[1]), Rect(x: 0, y: 0, width: 16, height: 16))
        XCTAssertEqual(vertexBounds(of: groups[0]), Rect(x: 0, y: 0, width: 16, height: 16))
        XCTAssertEqual(vertexBounds(of: groups[1]), Rect(x: 16, y: 0, width: 16, height: 16))
    }

    func testMarginAndSpacingOffsetTheAtlasLookup() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 4, rows: 1, margin: 1, spacing: 2)
        let groups = renderGroups(map(
            gids: [[2]],
            tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]
        ))

        XCTAssertEqual(textureBounds(of: try XCTUnwrap(groups.first)).minX, 19)
    }

    func testHorizontalFlipMirrorsTheTilesUVs() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 2, rows: 1)
        let unflipped = renderGroups(map(
            gids: [[1]],
            tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]
        ))
        let flipped = renderGroups(map(
            gids: [[Int(TiledGID(id: 1, flippedHorizontally: true).rawValue)]],
            tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]
        ))

        let plain = try XCTUnwrap(unflipped.first).triangles[1].textureTriangle
        let mirrored = try XCTUnwrap(flipped.first).triangles[1].textureTriangle
        XCTAssertEqual(textureBounds(of: flipped[0]), textureBounds(of: unflipped[0]))
        XCTAssertEqual(plain?.a.x, 0)
        XCTAssertEqual(mirrored?.a.x, 16)
    }

    func testVerticalFlipMirrorsTheTilesUVs() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 2, rows: 1)
        let flipped = renderGroups(map(
            gids: [[Int(TiledGID(id: 1, flippedVertically: true).rawValue)]],
            tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]
        ))

        let triangle = try XCTUnwrap(try XCTUnwrap(flipped.first).triangles[1].textureTriangle)
        XCTAssertEqual(triangle.a, Point(x: 0, y: 16))
    }

    func testOversizedTilesDrawAnchoredToTheCellsBottomLeft() throws {
        let sheet = tileSet(name: "tall", image: "tall.png", columns: 1, rows: 1, tileSize: 32)
        let groups = renderGroups(map(
            gids: [[1]],
            tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]
        ))

        XCTAssertEqual(vertexBounds(of: try XCTUnwrap(groups.first)), Rect(x: 0, y: 0, width: 32, height: 32))
    }

    func testHiddenLayersDoNotRenderAndOpacityCompounds() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 2, rows: 1)
        let reference = TiledTilesetReference(firstGid: 1, tileSet: sheet)

        XCTAssertTrue(renderGroups(map(gids: [[1]], tileSets: [reference], visible: false)).isEmpty)

        var sprite = SpriteComponent(
            entity: "map",
            type: .tileMap(map(gids: [[1]], tileSets: [reference], opacity: 0.5)),
            anchorPoint: .zero
        )
        sprite.opacity = 0.5
        let groups = sprite.renderGroups(
            cameraMatrix: .projection(rect: Rect(center: .zero, size: Size(width: 320, height: 320))),
            transform: TransformComponent(entity: "map", position: .zero),
            resourceManager: StubResourceManager()
        )
        XCTAssertEqual(groups.first?.opacity, 0.25)
    }

    func testOnlyTilesInsideTheCameraAreSubmitted() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 2, rows: 1)
        let filled = Array(repeating: Array(repeating: 1, count: 100), count: 100)
        let groups = renderGroups(
            map(gids: filled, tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]),
            cameraCenter: .zero,
            cameraSize: Size(width: 320, height: 320)
        )

        let group = try XCTUnwrap(groups.first)
        XCTAssertLessThan(group.triangles.count, 2 * 100 * 100)
        let bounds = vertexBounds(of: group)
        XCTAssertEqual(bounds.minX, 0)
        XCTAssertEqual(bounds.minY, 0)
        XCTAssertLessThanOrEqual(bounds.maxX, 176)
        XCTAssertLessThanOrEqual(bounds.maxY, 176)
    }

    func testCullingAccountsForTheEntitysOwnTransform() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 2, rows: 1)
        let filled = Array(repeating: Array(repeating: 1, count: 20), count: 20)
        let tileMap = map(gids: filled, tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)])

        let offscreen = renderGroups(tileMap, at: Point(x: 5000, y: 5000), cameraCenter: .zero)
        XCTAssertTrue(offscreen.isEmpty)

        let followed = renderGroups(tileMap, at: Point(x: 5000, y: 5000), cameraCenter: Point(x: 5100, y: 5100))
        XCTAssertFalse(followed.isEmpty)
    }

    func testAnimatedTilesAdvanceWithTheSpritesClock() throws {
        let animated = TiledTile(
            id: 0,
            class: "",
            animation: [TiledFrame(tileId: 0, duration: 100), TiledFrame(tileId: 1, duration: 100)]
        )
        let sheet = tileSet(
            name: "sheet",
            image: "sheet.png",
            columns: 2,
            rows: 1,
            tiles: [animated]
        )
        let tileMap = map(gids: [[1]], tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)])

        XCTAssertEqual(
            textureBounds(of: try XCTUnwrap(renderGroups(tileMap, animationTime: 50).first)).minX,
            0
        )
        XCTAssertEqual(
            textureBounds(of: try XCTUnwrap(renderGroups(tileMap, animationTime: 150).first)).minX,
            16
        )
        XCTAssertEqual(
            textureBounds(of: try XCTUnwrap(renderGroups(tileMap, animationTime: 250).first)).minX,
            0
        )
    }

    func testApplyDeltaAdvancesTheTileAnimationClockInMilliseconds() throws {
        let sheet = tileSet(name: "sheet", image: "sheet.png", columns: 2, rows: 1)
        var sprite = SpriteComponent(
            entity: "map",
            type: .tileMap(map(gids: [[1]], tileSets: [TiledTilesetReference(firstGid: 1, tileSet: sheet)]))
        )
        XCTAssertNil(sprite.applyDelta(0.25))
        XCTAssertEqual(sprite.tileAnimationTime, 250)
    }
}
