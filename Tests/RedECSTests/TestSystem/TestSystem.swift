import Foundation
@testable import RedECS

struct TestGlobalState: GameState {
    var entities: Set<EntityId> = []
    var count: Int32 = 0
    var text: String = ""
    
    var positions: [EntityId: TestTransformComponent] = [:]
    var movement: [EntityId: TestMovementComponent] = [:]
    
    var containedState: TestLocalState {
        get {
            TestLocalState(entities: entities, count: count)
        }
        set {
            entities = newValue.entities
            count = newValue.count
        }
    }
    
    var movementState: TestMovementComponentState {
        get { TestMovementComponentState(entities: entities, positions: positions, movement: movement) }
        set {
            entities = newValue.entities
            positions = newValue.positions
            movement = newValue.movement
        }
    }
}

enum TestGlobalAction: Equatable {
    case tick
    case updateVelocity(entity: EntityId, velocity: Point)
    case removeEntity(entity: EntityId)
}

final class TestGlobalEnvironment {
    
}

struct TestGlobalReducer: Reducer {
    func reduce(state: inout TestGlobalState, delta: Double, environment: TestGlobalEnvironment) -> GameEffect<TestGlobalState, TestGlobalAction> {
        .none
    }
    
    func reduce(
        state: inout TestGlobalState,
        action: TestGlobalAction,
        environment: TestGlobalEnvironment
    ) -> GameEffect<TestGlobalState, TestGlobalAction> {
        switch action {
        case .tick:
            state.count += 1
        case .removeEntity(let entity):
            return .system(.removeEntity(entity))
        default: break
        }
        return .none
    }
}

struct TestLocalState: GameState {
    var entities: Set<EntityId> = []
    var count: Int32
}

struct TestLocalReducer: Reducer {
    func reduce(state: inout TestLocalState, delta: Double, environment: TestGlobalEnvironment) -> GameEffect<TestLocalState, TestGlobalAction> {
            .none
    }
    
    func reduce(
        state: inout TestLocalState,
        action: TestGlobalAction,
        environment: TestGlobalEnvironment
    ) -> GameEffect<TestLocalState, TestGlobalAction> {
        switch action {
        case .tick:
            state.count += 1
        default: break
        }
        return .none
    }
}
