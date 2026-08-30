@testable import RedECS
import Geometry
import XCTest

private enum FlashAction: Equatable, Codable {
    case flashHit(EntityId)
    case flashDone(EntityId)
}

@CasePathable
private enum OpTestUmbrellaAction: Equatable, Codable {
    case flash(FlashAction)
    case ping
}

private struct FlashContext: GameState {
    var entities: EntityRepository = .init()
    var flashCount: [EntityId: Int] = [:]
}

private struct FlashReducer: Reducer {
    func reduce(state: inout FlashContext, delta: Double, environment: Void) -> GameEffect<FlashContext, FlashAction> {
        .none
    }

    func reduce(state: inout FlashContext, action: FlashAction, environment: Void) -> GameEffect<FlashContext, FlashAction> {
        switch action {
        case .flashHit(let id):
            return .operation(
                id,
                .wait(duration: 0.05)
                    .call(.flashDone(id))
            )
        case .flashDone(let id):
            state.flashCount[id, default: 0] += 1
            return .none
        }
    }
}

private struct OpTestState: GameState, OperationCapableGameState {
    var entities: EntityRepository = .init()
    var operation: [EntityId: OperationComponent<OpTestUmbrellaAction>] = [:]
    var transform: [EntityId: TransformComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
    var flashCount: [EntityId: Int] = [:]

    var flashContext: FlashContext {
        get { FlashContext(entities: entities, flashCount: flashCount) }
        set {
            entities = newValue.entities
            flashCount = newValue.flashCount
        }
    }
}

final class OperationEffectStoreTests: XCTestCase {
    private func makeStore() -> GameStore<AnyReducer<OpTestState, OpTestUmbrellaAction, Void>> {
        GameStore(
            state: OpTestState(),
            environment: (),
            reducer: zip(
                FlashReducer()
                    .pullback(
                        toLocalState: \OpTestState.flashContext,
                        action: OpTestUmbrellaAction.allCasePaths.flash
                    ),
                OperationsReducer<OpTestState>()
            ).eraseToAnyReducer(),
            registeredComponentTypes: [
                .init(keyPath: \.operation),
                .init(keyPath: \.transform),
                .init(keyPath: \.sprite)
            ]
        )
    }

    func testNarrowActionOperationMapsAppliesAndFiresThroughPullback() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("e1", []))

        store.sendAction(.flash(.flashHit("e1")))

        let component = store.state.operation["e1"]
        XCTAssertNotNil(component)
        XCTAssertEqual(component?.operations.count, 1)
        XCTAssertEqual(
            component?.operations.values.first,
            .wait(duration: 0.05).call(.flash(.flashDone("e1")))
        )

        store.sendDelta(0.1)
        store.sendDelta(0.1)

        XCTAssertEqual(store.state.flashCount["e1"], 1)
        XCTAssertEqual(store.state.operation["e1"]?.operations.count, 0)
    }

    func testKeyedOperationReplaces() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("e1", []))

        store.handleEffect(.operation("e1", key: "k", .wait(duration: 1)))
        store.handleEffect(.operation("e1", key: "k", .wait(duration: 2)))

        XCTAssertEqual(store.state.operation["e1"]?.operations.count, 1)
        XCTAssertEqual(store.state.operation["e1"]?.operations["k"], .wait(duration: 2))
    }

    func testKeylessOperationsStack() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("e1", []))

        store.handleEffect(.operation("e1", .wait(duration: 1)))
        store.handleEffect(.operation("e1", .wait(duration: 2)))

        XCTAssertEqual(store.state.operation["e1"]?.operations.count, 2)
    }

    func testRemoveOperationAndRemoveAllOperations() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("e1", []))

        store.handleEffect(.operation("e1", key: "a", .wait(duration: 1)))
        store.handleEffect(.operation("e1", key: "b", .wait(duration: 2)))

        store.handleEffect(.removeOperation("e1", key: "a"))
        XCTAssertEqual(store.state.operation["e1"]?.operations.count, 1)
        XCTAssertNil(store.state.operation["e1"]?.operations["a"])

        store.handleEffect(.removeAllOperations("e1"))
        XCTAssertEqual(store.state.operation["e1"]?.operations.count, 0)
    }

    func testWaitForCarryingOperationAppliesOnCompletion() {
        let store = makeStore()
        store.sendSystemAction(.addEntity("e2", []))

        store.handleEffect(.waitFor(PendingGameEffect(
            outstandingAction: .ping,
            effect: .operation("e2", key: "queued", .wait(duration: 1))
        )))
        XCTAssertNil(store.state.operation["e2"])

        store.sendAction(.ping)

        XCTAssertEqual(store.state.operation["e2"]?.operations["queued"], .wait(duration: 1))
    }

    func testStoredOperationComponentRoundTripsThroughJSON() throws {
        let store = makeStore()
        store.sendSystemAction(.addEntity("e1", []))
        store.handleEffect(.operation(
            "e1",
            key: "chain",
            .repeat(RepeatOperation(
                strategy: .times(2),
                operation: .wait(duration: 0.1).call(.flash(.flashDone("e1")))
            ))
        ))

        let component = try XCTUnwrap(store.state.operation["e1"])
        let data = try JSONEncoder().encode(component)
        let decoded = try JSONDecoder().decode(OperationComponent<OpTestUmbrellaAction>.self, from: data)
        XCTAssertEqual(decoded, component)
    }
}
