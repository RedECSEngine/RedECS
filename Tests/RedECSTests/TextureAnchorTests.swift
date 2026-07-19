import XCTest
import Geometry
import GeometryAlgorithms
import TiledInterpreter
@testable import RedECS

/// Anchor semantics parity: a `.texture` sprite's quad must land relative to
/// its transform position exactly as a `.shape` sprite's does — the anchor
/// point of the content lands on the position.
final class TextureAnchorTests: XCTestCase {
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

    static func textureResourceManager() -> StubResourceManager {
        let rm = StubResourceManager()
        rm.textures["atlas"] = .loaded(TextureMap(
            frames: [.init(
                filename: "frame-0",
                frame: .init(x: 0, y: 0, w: 16, h: 16),
                rotated: false, trimmed: false,
                spriteSourceSize: .init(x: 0, y: 0, w: 16, h: 16),
                sourceSize: .init(w: 16, h: 16),
                duration: nil
            )],
            meta: .init(image: nil, size: .init(w: 16, h: 16), format: nil, frameTags: nil)
        ))
        return rm
    }

    func worldBounds(of sprite: SpriteComponent, at position: Point, rm: ResourceManager) -> (min: Point, max: Point) {
        let transform = TransformComponent(entity: "e", position: position)
        let camera = Matrix3.projection(rect: Rect(center: position, size: Size(width: 480, height: 480)))
        let groups = sprite.renderGroups(cameraMatrix: camera, transform: transform, resourceManager: rm)
        let points = groups.flatMap { group in
            group.triangles
                .flatMap { [$0.triangle.a, $0.triangle.b, $0.triangle.c] }
                .map { $0.multiplyingMatrix(group.transformMatrix) }
        }
        let xs = points.map(\.x), ys = points.map(\.y)
        return (Point(x: xs.min()!, y: ys.min()!), Point(x: xs.max()!, y: ys.max()!))
    }

    func testTextureAnchorZeroPutsBottomLeftOnPosition() {
        let sprite = SpriteComponent(
            entity: "e",
            type: .texture(.init(textureId: "atlas", frameId: "frame-0")),
            anchorPoint: .zero
        )
        let bounds = worldBounds(of: sprite, at: Point(x: 100, y: 100), rm: Self.textureResourceManager())
        XCTAssertEqual(bounds.min, Point(x: 100, y: 100))
        XCTAssertEqual(bounds.max, Point(x: 116, y: 116))
    }

    func testTextureDefaultAnchorCentersOnPosition() {
        let sprite = SpriteComponent(
            entity: "e",
            type: .texture(.init(textureId: "atlas", frameId: "frame-0"))
        )
        let bounds = worldBounds(of: sprite, at: Point(x: 100, y: 100), rm: Self.textureResourceManager())
        XCTAssertEqual(bounds.min, Point(x: 92, y: 92))
        XCTAssertEqual(bounds.max, Point(x: 108, y: 108))
    }

    func testMissingNamedFrameRendersNothing() {
        let sprite = SpriteComponent(
            entity: "e",
            type: .texture(.init(textureId: "atlas", frameId: "no-such-frame"))
        )
        let transform = TransformComponent(entity: "e", position: Point(x: 100, y: 100))
        let camera = Matrix3.projection(rect: Rect(center: transform.position, size: Size(width: 480, height: 480)))
        let groups = sprite.renderGroups(
            cameraMatrix: camera,
            transform: transform,
            resourceManager: Self.textureResourceManager()
        )
        XCTAssertTrue(groups.isEmpty, "an unresolved named frame must not draw the whole sheet")
    }

    func testNilFrameRendersWholeTexture() {
        let sprite = SpriteComponent(
            entity: "e",
            type: .texture(.init(textureId: "atlas", frameId: nil))
        )
        let bounds = worldBounds(of: sprite, at: Point(x: 100, y: 100), rm: Self.textureResourceManager())
        XCTAssertEqual(bounds.min, Point(x: 92, y: 92))
        XCTAssertEqual(bounds.max, Point(x: 108, y: 108))
    }

    func testShapeAnchorZeroPutsBottomLeftOnPosition() {
        let sprite = SpriteComponent(
            entity: "e",
            type: .shape(.rect(Rect(origin: .zero, size: Size(width: 16, height: 16)))),
            anchorPoint: .zero
        )
        let bounds = worldBounds(of: sprite, at: Point(x: 100, y: 100), rm: StubResourceManager())
        XCTAssertEqual(bounds.min, Point(x: 100, y: 100))
        XCTAssertEqual(bounds.max, Point(x: 116, y: 116))
    }
}
