import XCTest
import Geometry
@testable import RedECS

struct TestHealthComponent: GameComponent {
    let entity: EntityId
    var value: Double = 100
    var shield: Double = 0

    init(entity: EntityId) { self.entity = entity }

    init(entity: EntityId, value: Double, shield: Double = 0) {
        self.entity = entity
        self.value = value
        self.shield = shield
    }
}

extension LerpKey where Value == Double {
    static var testHealth: Self { .init("TestHealthComponent.value") }
    static var testShield: Self { .init("TestHealthComponent.shield") }
}

struct DrainOperation<Action: Equatable & Codable>: ComponentOperation {
    typealias Component = TestHealthComponent

    static var operationTypeId: OperationTypeId { "test.drain" }

    var rate: Double
    var duration: Double
    var currentTime: Double = 0

    var isComplete: Bool { currentTime >= duration }

    mutating func run(
        id: EntityId,
        component: inout TestHealthComponent,
        delta: Double
    ) -> ComponentEffect<Action> {
        component.value = max(0, component.value - rate * delta)
        currentTime += delta
        return component.value <= 0 ? .removeEntity(id) : .none
    }

    mutating func reset() { currentTime = 0 }
}

extension TestHealthComponent: OperationSupportingComponent {
    static func bindOperationSupport<B: ComponentBinder>(_ binder: inout B) where B.Component == Self {
        binder.value(.testHealth, \.value)
        binder.value(.testShield, \.shield)
        binder.operation(DrainOperation<B.Action>.self)
    }
}

struct TestPlainComponent: GameComponent {
    let entity: EntityId
    init(entity: EntityId) { self.entity = entity }
}

enum OpenTestAction: Equatable, Codable {
    case healed
    case noop
}

struct OpenTestState: OperationCapableGameState {
    typealias GameAction = OpenTestAction

    var entities: EntityRepository = .init()
    var operation: [EntityId: OperationComponent<OpenTestAction>] = [:]
    var transform: [EntityId: TransformComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
    var health: [EntityId: TestHealthComponent] = [:]
    var plain: [EntityId: TestPlainComponent] = [:]
}

private let entity: EntityId = "e1"

private func makeRegistration() -> GameRegistration<OpenTestState, OpenTestAction> {
    GameRegistration<OpenTestState, OpenTestAction>()
        .component(\.operation)
        .component(\.transform)
        .component(\.sprite)
        .component(\.health)
        .component(\.plain)
}

private func makeState() -> OpenTestState {
    var state = OpenTestState()
    state.entities.addEntity(GameEntity(id: entity, tags: []))
    state.transform[entity] = TransformComponent(entity: entity)
    state.health[entity] = TestHealthComponent(entity: entity, value: 0, shield: 10)
    state.plain[entity] = TestPlainComponent(entity: entity)
    return state
}

final class ComponentRegistrationTests: XCTestCase {

    func testOptedInComponentRegistersItsValuesOperationAndTeardown() {
        let registration = makeRegistration()

        XCTAssertTrue(registration.registeredOperationTypeIds.contains("engine.lerp.TestHealthComponent.value"))
        XCTAssertTrue(registration.registeredOperationTypeIds.contains("engine.lerp.TestHealthComponent.shield"))
        XCTAssertTrue(registration.registeredOperationTypeIds.contains("test.drain"))

        XCTAssertTrue(
            registration.registeredOperationTypeIds
                .isSubset(of: registration.decoderTable.registeredTypeIds)
        )
    }

    func testEngineComponentsDeclareTheirOwnValues() {
        let registration = makeRegistration()
        XCTAssertTrue(registration.registeredOperationTypeIds.contains("engine.lerp.TransformComponent.position"))
        XCTAssertTrue(registration.registeredOperationTypeIds.contains("engine.lerp.SpriteComponent.opacity"))
    }

    func testPlainComponentRegistersTeardownOnly() {
        let registration = makeRegistration()
        XCTAssertTrue(registration.components.contains(.init(keyPath: \OpenTestState.plain)))
        XCTAssertFalse(registration.registeredOperationTypeIds.contains { $0.contains("TestPlainComponent") })
    }
}

final class LerpOperationTests: XCTestCase {

    private func run(
        _ operation: inout OperationType<OpenTestAction>,
        state: inout OpenTestState,
        ticks: Int,
        delta: Double
    ) {
        let registration = makeRegistration()
        for _ in 0..<ticks where !operation.isComplete {
            _ = operation.run(id: entity, state: &state, delta: delta, registration: registration)
        }
    }

    func testLandsExactlyOnTarget() {
        var state = makeState()
        var operation = OperationType<OpenTestAction>.lerp(.testHealth, to: 100, duration: 1)

        run(&operation, state: &state, ticks: 10, delta: 0.3)

        XCTAssertEqual(state.health[entity]?.value, 100)
        XCTAssertTrue(operation.isComplete)
    }

    func testTwoValuesOnTheSameComponentRunIndependently() {
        var state = makeState()
        var health = OperationType<OpenTestAction>.lerp(.testHealth, to: 100, duration: 1)
        var shield = OperationType<OpenTestAction>.lerp(.testShield, to: 0, duration: 1)
        let registration = makeRegistration()

        _ = health.run(id: entity, state: &state, delta: 0.5, registration: registration)
        _ = shield.run(id: entity, state: &state, delta: 0.5, registration: registration)

        XCTAssertEqual(state.health[entity]?.value ?? 0, 50, accuracy: 0.0001)
        XCTAssertEqual(state.health[entity]?.shield ?? 0, 5, accuracy: 0.0001)
    }

    func testByComposesOffTheCapturedStart() {
        var state = makeState()
        state.health[entity]?.value = 40
        var operation = OperationType<OpenTestAction>.lerp(.testHealth, by: 20, duration: 1)

        run(&operation, state: &state, ticks: 10, delta: 0.25)

        XCTAssertEqual(state.health[entity]?.value, 60)
    }

    func testIntValuesRoundRatherThanTruncate() {
        var state = makeState()
        state.transform[entity]?.zIndex = 0
        var operation = OperationType<OpenTestAction>.lerp(.zIndex, to: 10, duration: 1)
        let registration = makeRegistration()

        _ = operation.run(id: entity, state: &state, delta: 0.45, registration: registration)
        XCTAssertEqual(state.transform[entity]?.zIndex, 5)

        run(&operation, state: &state, ticks: 10, delta: 0.5)
        XCTAssertEqual(state.transform[entity]?.zIndex, 10)
    }

    func testPointValuesInterpolate() {
        var state = makeState()
        var operation = OperationType<OpenTestAction>.lerp(.position, to: Point(x: 100, y: 50), duration: 1)
        let registration = makeRegistration()

        _ = operation.run(id: entity, state: &state, delta: 0.5, registration: registration)

        XCTAssertEqual(state.transform[entity]?.position.x ?? 0, 50, accuracy: 0.0001)
        XCTAssertEqual(state.transform[entity]?.position.y ?? 0, 25, accuracy: 0.0001)
    }

    func testSetAppliesImmediately() {
        var state = makeState()
        var operation = OperationType<OpenTestAction>.set(.testHealth, to: 42)
        let registration = makeRegistration()

        _ = operation.run(id: entity, state: &state, delta: 1.0 / 60.0, registration: registration)

        XCTAssertEqual(state.health[entity]?.value, 42)
        XCTAssertTrue(operation.isComplete)
    }

    func testResetClearsTheCapturedStart() {
        var state = makeState()
        state.health[entity]?.value = 0
        var operation = LerpOperation(key: .testHealth, amount: .by(10), duration: 1)
        var registrationState = state

        operation.step(
            entity: entity,
            delta: 1,
            state: &registrationState,
            get: { id, s in s.health[id]?.value },
            set: { id, v, s in s.health[id]?.value = v }
        )
        XCTAssertEqual(operation.start, 0)

        operation.reset()
        XCTAssertNil(operation.start)
        XCTAssertEqual(operation.currentTime, 0)
    }
}

final class ComponentOperationTests: XCTestCase {

    func testRunsAcrossTicksAndKeepsItsOwnProgress() {
        var state = makeState()
        state.health[entity]?.value = 100
        var operation = OperationType<OpenTestAction>.custom(
            DrainOperation<OpenTestAction>(rate: 10, duration: 5)
        )
        let registration = makeRegistration()

        _ = operation.run(id: entity, state: &state, delta: 1, registration: registration)
        XCTAssertEqual(state.health[entity]?.value, 90)
        XCTAssertFalse(operation.isComplete)

        _ = operation.run(id: entity, state: &state, delta: 1, registration: registration)
        XCTAssertEqual(state.health[entity]?.value, 80)

        guard case .custom(let box) = operation,
              let drain = box.payload as? DrainOperation<OpenTestAction> else {
            return XCTFail("expected a custom DrainOperation, got \(operation)")
        }
        XCTAssertEqual(drain.currentTime, 2)
    }

    func testComponentEffectIsWidenedToAGameEffect() {
        var state = makeState()
        state.health[entity]?.value = 5
        var operation = OperationType<OpenTestAction>.custom(
            DrainOperation<OpenTestAction>(rate: 10, duration: 5)
        )
        let registration = makeRegistration()

        let effect = operation.run(id: entity, state: &state, delta: 1, registration: registration)

        guard case .system(let systemAction) = effect,
              case .removeEntity(let removed) = systemAction else {
            return XCTFail("expected a widened .system(.removeEntity), got \(effect)")
        }
        XCTAssertEqual(removed, entity)
    }

    func testCustomOperationNestedInASequenceRunsInOrder() {
        var state = makeState()
        state.health[entity]?.value = 100
        var operation = OperationType<OpenTestAction>
            .wait(duration: 1)
            .custom(DrainOperation<OpenTestAction>(rate: 10, duration: 1))
        let registration = makeRegistration()

        _ = operation.run(id: entity, state: &state, delta: 1, registration: registration)
        XCTAssertEqual(state.health[entity]?.value, 100, "the wait must run first")

        _ = operation.run(id: entity, state: &state, delta: 1, registration: registration)
        XCTAssertEqual(state.health[entity]?.value, 90)
    }
}

final class OpenOperationCodableTests: XCTestCase {

    private func decoder(_ registration: GameRegistration<OpenTestState, OpenTestAction>) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.operationDecoding] = registration.decoderTable
        return decoder
    }

    func testCustomOperationRoundTripsMidFlight() throws {
        var state = makeState()
        state.health[entity]?.value = 100
        let registration = makeRegistration()

        var operation = OperationType<OpenTestAction>
            .wait(duration: 1)
            .custom(DrainOperation<OpenTestAction>(rate: 10, duration: 5))
        _ = operation.run(id: entity, state: &state, delta: 1, registration: registration)
        _ = operation.run(id: entity, state: &state, delta: 1, registration: registration)

        let data = try JSONEncoder().encode(operation)
        let decoded = try decoder(registration).decode(OperationType<OpenTestAction>.self, from: data)

        XCTAssertEqual(decoded, operation)
    }

    func testALerpResumedFromASaveFinishesOnTheSameValue() throws {
        let registration = makeRegistration()

        var uninterrupted = makeState()
        var reference = OperationType<OpenTestAction>.lerp(.testHealth, to: 100, duration: 1, timing: .easeInOut)

        var interrupted = makeState()
        var saved = OperationType<OpenTestAction>.lerp(.testHealth, to: 100, duration: 1, timing: .easeInOut)

        _ = reference.run(id: entity, state: &uninterrupted, delta: 0.5, registration: registration)
        _ = saved.run(id: entity, state: &interrupted, delta: 0.5, registration: registration)

        let data = try JSONEncoder().encode(saved)
        var restored = try decoder(registration).decode(OperationType<OpenTestAction>.self, from: data)
        XCTAssertEqual(restored, saved)

        _ = reference.run(id: entity, state: &uninterrupted, delta: 0.5, registration: registration)
        _ = restored.run(id: entity, state: &interrupted, delta: 0.5, registration: registration)

        XCTAssertEqual(interrupted.health[entity]?.value, uninterrupted.health[entity]?.value)
        XCTAssertEqual(interrupted.health[entity]?.value, 100)
    }

    func testTheTypeTagCarriesTheLerpKey() throws {
        let operation = OperationType<OpenTestAction>.lerp(.testHealth, to: 100, duration: 1)
        let json = String(data: try JSONEncoder().encode(operation), encoding: .utf8) ?? ""
        XCTAssertTrue(
            json.contains("engine.lerp.TestHealthComponent.value"),
            "the tag should identify which registered lerp this is; got \(json)"
        )
    }

    func testDecodingWithoutARegistrationThrows() throws {
        let operation = OperationType<OpenTestAction>.custom(
            DrainOperation<OpenTestAction>(rate: 10, duration: 5)
        )
        let data = try JSONEncoder().encode(operation)

        XCTAssertThrowsError(try JSONDecoder().decode(OperationType<OpenTestAction>.self, from: data)) { error in
            guard case OperationCodingError.registrationNotConfigured = unwrap(error) else {
                return XCTFail("expected registrationNotConfigured, got \(error)")
            }
        }
    }

    func testDecodingAnUnregisteredOperationThrows() throws {
        let operation = OperationType<OpenTestAction>.custom(
            DrainOperation<OpenTestAction>(rate: 10, duration: 5)
        )
        let data = try JSONEncoder().encode(operation)

        let partial = GameRegistration<OpenTestState, OpenTestAction>().component(\.transform)
        let decoder = JSONDecoder()
        decoder.userInfo[.operationDecoding] = partial.decoderTable

        XCTAssertThrowsError(try decoder.decode(OperationType<OpenTestAction>.self, from: data)) { error in
            guard case OperationCodingError.unknownOperationType = unwrap(error) else {
                return XCTFail("expected unknownOperationType, got \(error)")
            }
        }
    }

    private func unwrap(_ error: Error) -> Error {
        if case DecodingError.valueNotFound(_, let context) = error, let underlying = context.underlyingError {
            return underlying
        }
        if case DecodingError.dataCorrupted(let context) = error, let underlying = context.underlyingError {
            return underlying
        }
        return error
    }
}

import RedECSAppleSupport

final class OpenOperationStoreTests: XCTestCase {

    private struct PassthroughReducer: Reducer {
        typealias State = OpenTestState
        typealias Action = OpenTestAction
        typealias Environment = Void

        func reduce(
            state: inout OpenTestState,
            action: OpenTestAction,
            environment: Void
        ) -> GameEffect<OpenTestState, OpenTestAction> {
            .none
        }
    }

    func testAStateSavedMidOperationRestoresAndKeepsRunning() throws {
        let registration = makeRegistration()
        let reducer = zip(
            PassthroughReducer(),
            OperationReducer<OpenTestState>(registration: registration)
        ).eraseToAnyReducer()

        var state = makeState()
        state.health[entity]?.value = 100
        state.operation[entity] = OperationComponent(
            entity: entity,
            operation: .custom(DrainOperation<OpenTestAction>(rate: 10, duration: 5))
        )

        let store = GameStore(
            state: state,
            environment: (),
            reducer: reducer,
            registration: registration
        )

        store.sendDelta(1)
        XCTAssertEqual(store.state.health[entity]?.value, 90)

        let data = try store.saveState()
        let restored = try GameStore(
            data: data,
            environment: (),
            reducer: reducer,
            registration: registration
        )

        XCTAssertEqual(restored.state.health[entity]?.value, 90)
        restored.sendDelta(1)
        XCTAssertEqual(restored.state.health[entity]?.value, 80, "the restored operation kept its progress")
    }
}
