import XCTest
import Geometry
import GeometryAlgorithms
import RedECS
import TiledInterpreter
@testable import RedHUD

private struct TestState: GameState {
    var entities: EntityRepository = .init()
    var score: Int = 0
}

private final class FakeRenderer: Renderer {
    var viewportSize: Size = Size(width: 480, height: 320)
    var queuedWork: [RenderGroup] = []
    func setProjectionMatrix(_ matrix: Matrix3) {}
}

private final class FakeResourceManager: ResourceManager {
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

private struct FakeEnvironment: RenderingEnvironment {
    var renderer: Renderer { fakeRenderer }
    var resourceManager: ResourceManager { fakeResourceManager }
    let fakeRenderer: FakeRenderer
    let fakeResourceManager = FakeResourceManager()
}

final class HUDRenderingReducerTests: XCTestCase {
    private var renderer: FakeRenderer!
    private var environment: FakeEnvironment!
    private var state = TestState()

    override func setUp() {
        renderer = FakeRenderer()
        environment = FakeEnvironment(fakeRenderer: renderer)
        state = TestState()
    }

    func testNilContentRendersNothing() {
        let reducer = HUDRenderingReducer<TestState> { _ in nil }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertTrue(renderer.queuedWork.isEmpty)
    }

    func testContentDerivesFromState() {
        let reducer = HUDRenderingReducer<TestState> { state in
            state.score > 0
                ? AnyHUDView(Rectangle().frame(width: 10, height: 10))
                : nil
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertTrue(renderer.queuedWork.isEmpty)

        state.score = 5
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertEqual(renderer.queuedWork.count, 1)
    }

    func testGroupsAreScreenSpaceInPaintOrderAndCentered() {
        let reducer = HUDRenderingReducer<TestState> { _ in
            AnyHUDView(HStack {
                Rectangle().frame(width: 20, height: 10)
                Rectangle().frame(width: 20, height: 10)
            })
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)

        XCTAssertEqual(renderer.queuedWork.count, 2)
        for (i, group) in renderer.queuedWork.enumerated() {
            XCTAssertEqual(group.zIndex, i)
            if case .world = group.projectionSpace {
                XCTFail("HUD groups must be screen-space")
            }
        }
        // A 40x10 root centered in 480x320 starts at (220, 155).
        let firstOrigin = Point.zero.multiplyingMatrix(renderer.queuedWork[0].transformMatrix)
        XCTAssertEqual(firstOrigin, Point(x: 220, y: 155))
    }

    func testZeroViewportRendersNothing() {
        renderer.viewportSize = .zero
        let reducer = HUDRenderingReducer<TestState> { _ in
            AnyHUDView(Rectangle())
        }
        _ = reducer.reduce(state: &state, delta: 1, environment: environment)
        XCTAssertTrue(renderer.queuedWork.isEmpty)
    }
}
