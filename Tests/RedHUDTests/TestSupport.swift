import Geometry
import GeometryAlgorithms
import RedECS
import TiledInterpreter
@testable import RedHUD

struct TestState: RenderableGameState {
    var entities: EntityRepository = .init()
    var score: Int = 0
    var transform: [EntityId: TransformComponent] = [:]
    var camera: [EntityId: CameraComponent] = [:]
}

final class FakeRenderer: Renderer {
    var viewportSize: Size = Size(width: 480, height: 320)
    var queuedWork: [RenderGroup] = []
    func setProjectionMatrix(_ matrix: Matrix3) {}
}

final class FakeResourceManager: ResourceManager {
    var textures: [TextureId: Resource<TextureMap>] = [:]
    var animations: [TextureId: SpriteAnimationDictionary] = [:]
    var tileMaps: [String: TiledMapJSON] = [:]
    var tileSets: [String: TiledTilesetJSON] = [:]
    var fonts: [String: BitmapFont] = [:]

    func preload(_ assets: [LoadableResource]) -> Future<Void, Error> { .just(()) }
    func startTextureLoadIfNeeded(textureId: TextureId) -> Future<Void, Error> { .just(()) }
    func loadJSONFile<T: Decodable>(_ name: String, decodedAs: T.Type) -> Future<T, Error> {
        Future { _ in }
    }
    func loadTiledMap(_ name: String) -> Future<TiledMapJSON, Error> {
        Future { _ in }
    }
    func loadBitmapFontTextFile(_ name: String) -> Future<BitmapFont, Error> {
        Future { _ in }
    }
}

struct FakeEnvironment: RenderingEnvironment {
    var renderer: Renderer { fakeRenderer }
    var resourceManager: ResourceManager { fakeResourceManager }
    let fakeRenderer: FakeRenderer
    let fakeResourceManager = FakeResourceManager()
}

extension HUDView {
    /// Pre-resolve-refactor test shape: resolve at the given size and
    /// flatten to transform-composed render groups.
    func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        _resolve(proposed: ProposedSize(size), context: context).flattenedGroups()
    }
}
