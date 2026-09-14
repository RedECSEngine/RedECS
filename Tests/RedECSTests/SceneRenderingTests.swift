@testable import RedECS
import Geometry
import GeometryAlgorithms
import TiledInterpreter
import XCTest

private struct SceneRenderTestState: RenderableGameState, SceneCapableGameState {
    var entities: EntityRepository = .init()
    var transform: [EntityId: TransformComponent] = [:]
    var camera: [EntityId: CameraComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
    var scene: [EntityId: SceneComponent] = [:]
    var sceneManager: SceneManagerState = .init()
}

private final class FakeRenderer: Renderer {
    var viewportSize: Size = Size(width: 480, height: 320)
    var queuedWork: [RenderGroup] = []
    func setProjectionMatrix(_ matrix: Matrix3) { }
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
    let fakeRenderer = FakeRenderer()
    let fakeResourceManager = FakeResourceManager()
}

final class SceneRenderingTests: XCTestCase {
    private var state = SceneRenderTestState()
    private var environment = FakeEnvironment()

    override func setUp() {
        super.setUp()
        state = SceneRenderTestState()
        environment = FakeEnvironment()

        state.entities.addEntity(GameEntity(id: "cam", tags: []))
        state.transform["cam"] = TransformComponent(entity: "cam")
        state.camera["cam"] = CameraComponent(entity: "cam")

        addShapeEntity("world", parent: nil, color: .red)
        addScene("a", childColor: .green)
        addScene("b", childColor: .blue)
    }

    private func addShapeEntity(_ id: EntityId, parent: EntityId?, color: Color) {
        state.entities.addEntity(GameEntity(id: id, tags: []), under: parent)
        state.transform[id] = TransformComponent(entity: id)
        var sprite = SpriteComponent(entity: id)
        sprite.type = .shape(.rect(Rect(origin: .zero, size: Size(width: 8, height: 8))))
        sprite.fillColor = color
        state.sprite[id] = sprite
    }

    private func addScene(_ id: EntityId, childColor: Color) {
        state.entities.addEntity(GameEntity(id: id, tags: []))
        state.transform[id] = TransformComponent(entity: id)
        state.scene[id] = SceneComponent(entity: id)
        addShapeEntity("\(id)Child", parent: id, color: childColor)
    }

    private func render(sceneAware: Bool = true) -> [RenderGroup] {
        environment.fakeRenderer.queuedWork = []
        let reducer: RenderingReducer<SceneRenderTestState> = sceneAware
            ? .sceneAware(renderableComponentTypes: [.init(keyPath: \.sprite)])
            : RenderingReducer(renderableComponentTypes: [.init(keyPath: \.sprite)])
        var renderState = state
        _ = reducer.reduce(state: &renderState, delta: 1, environment: environment)
        return environment.fakeRenderer.queuedWork
    }

    private func count(of groups: [RenderGroup], _ color: Color) -> Int {
        groups.filter { $0.color == color }.count
    }

    func testDefaultSceneDrawsWhenNoSceneIsActive() {
        let groups = render()
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(count(of: groups, .red), 1)
    }

    func testOnlyActiveSceneSubtreeDraws() {
        state.sceneManager.activeSceneId = "a"
        let groups = render()
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(count(of: groups, .green), 1)
    }

    func testSequentialTransitionDrawsOneSidePerPhase() {
        state.sceneManager.activeSceneId = "a"
        state.sceneManager.transition = ActiveSceneTransition(
            outgoingSceneId: "a",
            incomingSceneId: "b",
            transition: .fade(duration: 1),
            elapsed: 0.25
        )
        let firstHalf = render()
        XCTAssertEqual(firstHalf.count, 1)
        XCTAssertEqual(count(of: firstHalf, .green), 1)
        XCTAssertTrue(firstHalf.allSatisfy { $0.shader == .fade(time: 0.5) })
        XCTAssertTrue(firstHalf.allSatisfy { $0.zIndex == 0 })

        state.sceneManager.transition?.elapsed = 0.75
        let secondHalf = render()
        XCTAssertEqual(secondHalf.count, 1)
        XCTAssertEqual(count(of: secondHalf, .blue), 1)
        XCTAssertTrue(secondHalf.allSatisfy { $0.shader == .fade(time: 0.5) })
        XCTAssertTrue(secondHalf.allSatisfy {
            $0.zIndex == RenderingReducer<SceneRenderTestState>.incomingSceneZIndexOffset
        })
    }

    func testCrossoverTransitionDrawsBothSidesWithIncomingBeneath() {
        state.sceneManager.activeSceneId = "a"
        state.sceneManager.transition = ActiveSceneTransition(
            outgoingSceneId: "a",
            incomingSceneId: "b",
            transition: .dissolve(duration: 1),
            elapsed: 0.25
        )
        let groups = render()
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(count(of: groups, .green), 1)
        XCTAssertEqual(count(of: groups, .blue), 1)

        let outgoing = groups.filter { $0.color == .green }
        XCTAssertTrue(outgoing.allSatisfy { $0.shader == .turnOff(time: 0.25) })
        XCTAssertTrue(outgoing.allSatisfy { $0.zIndex == 0 })

        let incoming = groups.filter { $0.color == .blue }
        XCTAssertTrue(incoming.allSatisfy { $0.shader == nil })
        XCTAssertTrue(incoming.allSatisfy {
            $0.zIndex == RenderingReducer<SceneRenderTestState>.incomingSceneZIndexOffset
        })
    }

    func testTransitionFromDefaultSceneTreatsRootEntitiesAsOutgoing() {
        state.sceneManager.transition = ActiveSceneTransition(
            outgoingSceneId: nil,
            incomingSceneId: "b",
            transition: .dissolve(duration: 1),
            elapsed: 0.5
        )
        let groups = render()
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(count(of: groups, .red), 1)
        XCTAssertEqual(count(of: groups, .blue), 1)
        XCTAssertTrue(groups.filter { $0.color == .red }.allSatisfy { $0.shader == .turnOff(time: 0.5) })
    }

    func testPlainReducerWithoutDispositionDrawsEverything() {
        state.sceneManager.activeSceneId = "a"
        let groups = render(sceneAware: false)
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(count(of: groups, .red), 1)
        XCTAssertEqual(count(of: groups, .green), 1)
        XCTAssertEqual(count(of: groups, .blue), 1)
        XCTAssertTrue(groups.allSatisfy { $0.shader == nil })
        XCTAssertTrue(groups.allSatisfy { $0.zIndex == 0 })
    }
}
