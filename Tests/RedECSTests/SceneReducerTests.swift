@testable import RedECS
import Geometry
import XCTest

private enum SceneTestAction: Equatable, Codable {
    case scene(SceneAction)
    case ping

    static func toScene(_ action: SceneTestAction) -> SceneAction? {
        if case .scene(let sceneAction) = action { return sceneAction }
        return nil
    }
}

private struct SceneTestState: GameState, OperationCapableGameState, SceneCapableGameState {
    var entities: EntityRepository = .init()
    var operation: [EntityId: OperationComponent<SceneTestAction>] = [:]
    var transform: [EntityId: TransformComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
    var scene: [EntityId: SceneComponent] = [:]
    var sceneManager: SceneManagerState = .init()
}

final class SceneReducerTests: XCTestCase {
    private func makeStore() -> GameStore<AnyReducer<SceneTestState, SceneTestAction, Void>> {
        GameStore(
            state: SceneTestState(),
            environment: (),
            reducer: zip(
                SceneReducer()
                    .pullback(
                        toLocalState: \SceneTestState.sceneContext,
                        toLocalAction: SceneTestAction.toScene,
                        toGlobalAction: SceneTestAction.scene
                    ),
                OperationReducer<SceneTestAction>()
                    .pullback(toLocalState: \.operationContext)
            ).eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.operation),
                .init(keyPath: \.transform),
                .init(keyPath: \.sprite),
                .init(keyPath: \.scene)
            ]
        )
    }

    private func addScene(
        _ id: EntityId,
        children: [EntityId],
        keepAlive: Bool = false,
        cancelsPendingEffects: Bool = false,
        to store: GameStore<AnyReducer<SceneTestState, SceneTestAction, Void>>
    ) {
        store.sendSystemAction(.addEntity(id, []))
        store.sendSystemAction(.addComponent(
            SceneComponent(
                entity: id,
                keepAliveOnDismiss: keepAlive,
                cancelsPendingEffectsOnDismiss: cancelsPendingEffects
            ),
            into: \.scene
        ))
        for child in children {
            store.sendSystemAction(.addEntity(child, []))
            store.sendSystemAction(.setParent(child, id))
            store.sendSystemAction(.addComponent(TransformComponent(entity: child), into: \.transform))
        }
    }

    func testPresentWithoutTransitionSwapsImmediately() {
        let store = makeStore()
        addScene("menu", children: ["title"], to: store)

        store.sendAction(.scene(.presentScene("menu", nil)))

        XCTAssertEqual(store.state.sceneManager.activeSceneId, "menu")
        XCTAssertNil(store.state.sceneManager.transition)
    }

    func testTransitionProgressesAndSwapsOnCompletion() {
        let store = makeStore()
        addScene("menu", children: [], to: store)

        store.sendAction(.scene(.presentScene("menu", .fade(duration: 1))))
        XCTAssertNil(store.state.sceneManager.activeSceneId)
        XCTAssertEqual(store.state.sceneManager.transition?.incomingSceneId, "menu")

        store.sendDelta(0.4)
        XCTAssertEqual(store.state.sceneManager.transition?.elapsed ?? 0, 0.4, accuracy: 1e-9)
        XCTAssertNil(store.state.sceneManager.activeSceneId)

        store.sendDelta(0.7)
        XCTAssertEqual(store.state.sceneManager.activeSceneId, "menu")
        XCTAssertNil(store.state.sceneManager.transition)
    }

    func testTeardownDestroysChildrenButKeepsSceneRoot() {
        let store = makeStore()
        addScene("level", children: ["hero", "enemy"], to: store)
        addScene("menu", children: [], to: store)

        store.sendAction(.scene(.presentScene("level", nil)))
        store.sendAction(.scene(.presentScene("menu", nil)))

        XCTAssertEqual(store.state.sceneManager.activeSceneId, "menu")
        XCTAssertNotNil(store.state.entities["level"])
        XCTAssertNotNil(store.state.scene["level"])
        XCTAssertNil(store.state.entities["hero"])
        XCTAssertNil(store.state.entities["enemy"])
        XCTAssertNil(store.state.transform["hero"])
        XCTAssertEqual(store.state.entities.descendants(of: "level"), [])
    }

    func testKeepAliveSceneSurvivesDismissAndRePresents() {
        let store = makeStore()
        addScene("pause", children: ["resumeButton"], keepAlive: true, to: store)
        addScene("level", children: [], to: store)

        store.sendAction(.scene(.presentScene("pause", nil)))
        store.sendAction(.scene(.presentScene("level", nil)))

        XCTAssertNotNil(store.state.entities["resumeButton"])
        XCTAssertEqual(store.state.entities.descendants(of: "pause"), ["resumeButton"])

        store.sendAction(.scene(.presentScene("pause", nil)))
        XCTAssertEqual(store.state.sceneManager.activeSceneId, "pause")
        XCTAssertNotNil(store.state.entities["resumeButton"])
    }

    func testDismissingToDefaultSceneNeverDestroysRootEntities() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("worldEntity", []))
        addScene("menu", children: ["title"], to: store)

        store.sendAction(.scene(.presentScene("menu", nil)))
        XCTAssertNotNil(store.state.entities["worldEntity"])

        store.sendAction(.scene(.dismissScene(nil)))
        XCTAssertNil(store.state.sceneManager.activeSceneId)
        XCTAssertNotNil(store.state.entities["worldEntity"])
        XCTAssertNil(store.state.entities["title"])
    }

    func testCancelPendingEffectsOnDismissClearsWaits() {
        let store = makeStore()
        addScene("level", children: [], cancelsPendingEffects: true, to: store)
        store.sendSystemAction(.addEntity("e1", []))

        store.sendAction(.scene(.presentScene("level", nil)))
        store.handleEffect(.waitFor(PendingGameEffect(
            outstandingAction: .ping,
            effect: .operation("e1", key: "queued", .wait(duration: 1))
        )))

        store.sendAction(.scene(.dismissScene(nil)))
        store.sendAction(.ping)
        XCTAssertNil(store.state.operation["e1"]?.operations["queued"])
    }

    func testPendingEffectsSurviveDismissByDefault() {
        let store = makeStore()
        addScene("level", children: [], to: store)
        store.sendSystemAction(.addEntity("e1", []))

        store.sendAction(.scene(.presentScene("level", nil)))
        store.handleEffect(.waitFor(PendingGameEffect(
            outstandingAction: .ping,
            effect: .operation("e1", key: "queued", .wait(duration: 1))
        )))

        store.sendAction(.scene(.dismissScene(nil)))
        store.sendAction(.ping)
        XCTAssertNotNil(store.state.operation["e1"]?.operations["queued"])
    }

    func testPresentWhileTransitioningCompletesInFlightFirst() {
        let store = makeStore()
        addScene("a", children: ["aChild"], to: store)
        addScene("b", children: [], to: store)
        addScene("c", children: [], to: store)

        store.sendAction(.scene(.presentScene("a", nil)))
        store.sendAction(.scene(.presentScene("b", .fade(duration: 1))))
        store.sendDelta(0.3)

        store.sendAction(.scene(.presentScene("c", .fade(duration: 1))))

        XCTAssertNil(store.state.entities["aChild"])
        XCTAssertEqual(store.state.sceneManager.transition?.outgoingSceneId, "b")
        XCTAssertEqual(store.state.sceneManager.transition?.incomingSceneId, "c")
        XCTAssertEqual(store.state.sceneManager.transition?.elapsed, 0)

        store.sendDelta(1.1)
        XCTAssertEqual(store.state.sceneManager.activeSceneId, "c")
    }

    func testExternallyRemovingActiveSceneClearsIt() {
        let store = makeStore()
        addScene("menu", children: ["title"], to: store)
        store.sendAction(.scene(.presentScene("menu", nil)))

        store.sendSystemAction(.removeEntity("menu"))

        XCTAssertNil(store.state.sceneManager.activeSceneId)
        XCTAssertNil(store.state.entities["title"])
    }

    func testExternallyRemovingTransitionSideCompletesWithoutTeardown() {
        let store = makeStore()
        addScene("a", children: ["aChild"], to: store)
        addScene("b", children: [], to: store)

        store.sendAction(.scene(.presentScene("a", nil)))
        store.sendAction(.scene(.presentScene("b", .fade(duration: 1))))
        store.sendDelta(0.2)

        store.sendSystemAction(.removeEntity("b"))

        XCTAssertNil(store.state.sceneManager.transition)
        XCTAssertEqual(store.state.sceneManager.activeSceneId, "a")
        XCTAssertNotNil(store.state.entities["aChild"])
    }

    func testStateRoundTripsMidTransitionAndCompletes() throws {
        let store = makeStore()
        addScene("a", children: ["aChild"], to: store)
        addScene("b", children: [], to: store)
        store.sendAction(.scene(.presentScene("a", nil)))
        store.sendAction(.scene(.presentScene("b", .dissolve(duration: 1))))
        store.sendDelta(0.4)

        let data = try JSONEncoder().encode(store.state)
        let restored = try JSONDecoder().decode(SceneTestState.self, from: data)
        XCTAssertEqual(restored, store.state)

        let resumedStore = makeStore()
        resumedStore.perform { state, _ in
            state = restored
            return .none
        }
        resumedStore.sendDelta(0.7)

        XCTAssertEqual(resumedStore.state.sceneManager.activeSceneId, "b")
        XCTAssertNil(resumedStore.state.sceneManager.transition)
        XCTAssertNil(resumedStore.state.entities["aChild"])
    }
}
