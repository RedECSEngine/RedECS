import Foundation
@testable import RedECS

struct TestGlobalState: GameState {
    var entities: Set<EntityId> = []
    var count: Int = 0
    var text: String = ""
    
    var positions: [EntityId: TestPositionComponent] = [:]
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

enum TestGlobalAction {
    case tick
    case updateVelocity(entity: EntityId, velocity: Point)
    case removeEntity(entity: EntityId)
}

final class TestGlobalEnvironment: GameEnvironment {
    
}

struct TestGlobalReducer: Reducer {
    func reduce(
        state: inout TestGlobalState,
        action: TestGlobalAction,
        environment: TestGlobalEnvironment
    ) -> GameEffect<TestGlobalState, TestGlobalAction> {
        switch action {
        case .tick:
            state.count += 1
        case .removeEntity(let entity):
            return .systemAction(.removeEntity(entity))
        default: break
        }
        return .none
    }
}

struct TestLocalState: GameState {
    var entities: Set<EntityId> = []
    var count: Int
}

struct TestLocalReducer: Reducer {
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
