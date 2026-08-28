@testable import RedECS
import Geometry
import XCTest

private enum PresentTestAction: Equatable, Codable {
    case ping
}

private struct PresentTestState: GameState, OperationCapableGameState {
    typealias GameAction = PresentTestAction
    var entities: EntityRepository = .init()
    var operation: [EntityId: OperationComponent<PresentTestAction>] = [:]
    var transform: [EntityId: TransformComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
}

final class PresentSceneTests: XCTestCase {
    private func makeStore() -> GameStore<AnyReducer<PresentTestState, PresentTestAction, Void>> {
        GameStore(
            state: PresentTestState(),
            environment: (),
            reducer: OperationReducer<PresentTestAction>()
                .pullback(toLocalState: \PresentTestState.operationContext)
                .eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.operation),
                .init(keyPath: \.transform),
                .init(keyPath: \.sprite)
            ]
        )
    }

    private func addScene(
        _ id: EntityId,
        children: [EntityId],
        hidden: Bool,
        to store: GameStore<AnyReducer<PresentTestState, PresentTestAction, Void>>
    ) {
        store.sendSystemAction(.addEntity(id, []))
        var rootTransform = TransformComponent(entity: id)
        rootTransform.isHidden = hidden
        store.sendSystemAction(.addComponent(rootTransform, into: \.transform))
        store.sendSystemAction(.addComponent(SpriteComponent(entity: id), into: \.sprite))
        for child in children {
            store.sendSystemAction(.addEntity(child, []))
            store.sendSystemAction(.setParent(child, id))
            store.sendSystemAction(.addComponent(TransformComponent(entity: child), into: \.transform))
            store.sendSystemAction(.addComponent(SpriteComponent(entity: child), into: \.sprite))
        }
    }

    func testSetHiddenTogglesTransformVisibility() {
        let store = makeStore()
        addScene("a", children: [], hidden: false, to: store)

        store.sendSystemAction(.setHidden("a", true))
        XCTAssertEqual(store.state.transform["a"]?.isHidden, true)

        store.sendSystemAction(.setHidden("a", false))
        XCTAssertEqual(store.state.transform["a"]?.isHidden, false)
    }

    func testImmediatePresentSwapsVisibility() {
        let store = makeStore()
        addScene("a", children: ["a1"], hidden: false, to: store)
        addScene("b", children: ["b1"], hidden: true, to: store)

        store.handleEffect(.presentScene(hide: "a", show: "b"))

        XCTAssertEqual(store.state.transform["a"]?.isHidden, true)
        XCTAssertEqual(store.state.transform["b"]?.isHidden, false)
        XCTAssertNotNil(store.state.entities["a1"])
    }

    func testImmediatePresentWithDestroyRemovesOutgoingSubtree() {
        let store = makeStore()
        addScene("a", children: ["a1"], hidden: false, to: store)
        addScene("b", children: [], hidden: true, to: store)

        store.handleEffect(.presentScene(hide: "a", show: "b", destroyOutgoing: true))

        XCTAssertNil(store.state.entities["a"])
        XCTAssertNil(store.state.entities["a1"])
        XCTAssertNil(store.state.sprite["a1"])
        XCTAssertEqual(store.state.transform["b"]?.isHidden, false)
    }

    func testSequentialFadeTimeline() {
        let store = makeStore()
        addScene("a", children: ["a1"], hidden: false, to: store)
        addScene("b", children: ["b1"], hidden: false, to: store)

        store.handleEffect(.presentScene(hide: "a", show: "b", transition: .fade(duration: 1)))
        XCTAssertEqual(store.state.transform["b"]?.isHidden, true)

        store.sendDelta(0.25)
        XCTAssertEqual(store.state.sprite["a1"]?.shader, .fade(time: 0.5))
        XCTAssertEqual(store.state.transform["a"]?.isHidden, false)
        XCTAssertEqual(store.state.transform["b"]?.isHidden, true)

        store.sendDelta(0.25)
        XCTAssertNil(store.state.sprite["a1"]?.shader)

        store.sendDelta(0.1)
        XCTAssertEqual(store.state.transform["a"]?.isHidden, true)
        XCTAssertEqual(store.state.transform["b"]?.isHidden, false)

        store.sendDelta(0.25)
        guard case .fade(let inTime)? = store.state.sprite["b1"]?.shader else {
            return XCTFail("expected fade on incoming child")
        }
        XCTAssertEqual(inTime, 0.5, accuracy: 1e-9)

        store.sendDelta(0.3)
        XCTAssertNil(store.state.sprite["b1"]?.shader)
        XCTAssertEqual(store.state.operation["a"]?.operations.count ?? 0, 0)
        XCTAssertEqual(store.state.operation["b"]?.operations.count ?? 0, 0)
    }

    func testSequentialDestroyRemovesOutgoingAfterFadeOut() {
        let store = makeStore()
        addScene("a", children: ["a1"], hidden: false, to: store)
        addScene("b", children: [], hidden: true, to: store)

        store.handleEffect(.presentScene(hide: "a", show: "b", transition: .fade(duration: 1), destroyOutgoing: true))

        store.sendDelta(0.6)
        XCTAssertNotNil(store.state.entities["a"])
        store.sendDelta(0.1)
        XCTAssertNil(store.state.entities["a"])
        XCTAssertNil(store.state.entities["a1"])
    }

    func testCrossoverDissolveShowsIncomingBeneathOutgoing() {
        let store = makeStore()
        addScene("a", children: ["a1"], hidden: false, to: store)
        addScene("b", children: ["b1"], hidden: true, to: store)

        store.handleEffect(.presentScene(hide: "a", show: "b", transition: .dissolve(duration: 1)))
        XCTAssertEqual(store.state.transform["b"]?.isHidden, false)

        store.sendDelta(0.25)
        XCTAssertEqual(store.state.sprite["a1"]?.shader, .turnOff(time: 0.25))
        XCTAssertNil(store.state.sprite["b1"]?.shader)
        XCTAssertEqual(store.state.transform["a"]?.isHidden, false)

        store.sendDelta(0.8)
        XCTAssertNil(store.state.sprite["a1"]?.shader)
        store.sendDelta(0.1)
        XCTAssertEqual(store.state.transform["a"]?.isHidden, true)
    }

    func testRePresentingReplacesInFlightTransition() {
        let store = makeStore()
        addScene("a", children: [], hidden: false, to: store)
        addScene("b", children: [], hidden: true, to: store)

        store.handleEffect(.presentScene(hide: "a", show: "b", transition: .crossFade(duration: 1)))
        store.sendDelta(0.4)
        guard let midFlight = outgoingSubtreeShader(in: store) else {
            return XCTFail("expected in-flight subtreeShader")
        }
        XCTAssertEqual(midFlight.currentTime, 0.4, accuracy: 1e-9)

        store.handleEffect(.presentScene(hide: "a", show: "b", transition: .crossFade(duration: 1)))
        guard let restarted = outgoingSubtreeShader(in: store) else {
            return XCTFail("expected replaced subtreeShader")
        }
        XCTAssertEqual(restarted.currentTime, 0, accuracy: 1e-9)
    }

    private func outgoingSubtreeShader(
        in store: GameStore<AnyReducer<PresentTestState, PresentTestAction, Void>>
    ) -> SubtreeShaderOperation? {
        guard case .sequence(let seq)? = store.state.operation["a"]?.operations[SceneTransition.operationKey],
              case .subtreeShader(let op)? = seq.operations.first
        else { return nil }
        return op
    }

    func testShowOnlyPresentUnhidesTarget() {
        let store = makeStore()
        addScene("b", children: [], hidden: true, to: store)

        store.handleEffect(.presentScene(show: "b"))
        XCTAssertEqual(store.state.transform["b"]?.isHidden, false)
    }
}
