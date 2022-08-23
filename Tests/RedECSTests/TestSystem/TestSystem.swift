@testable import RedECS

import Geometry
import RedECSBasicComponents

struct TestGlobalState: GameState {
    var entities: EntityRepository = .init()
    var count: Int32 = 0
    var text: String = ""
    
    var transform: [EntityId: TransformComponent] = [:]
    var movement: [EntityId: MovementComponent] = [:]
    
    var containedState: TestLocalState {
        get {
            TestLocalState(entities: entities, count: count)
        }
        set {
            entities = newValue.entities
            count = newValue.count
        }
    }
    
    var movementContext: MovementReducerContext {
        get { MovementReducerContext(entities: entities, transform: transform, movement: movement) }
        set {
            entities = newValue.entities
            transform = newValue.transform
            movement = newValue.movement
        }
    }
}

enum TestGlobalAction: Equatable {
    case incrementCount
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
        case .incrementCount:
            state.count += 1
        case .removeEntity(let entity):
            return .system(.removeEntity(entity))
        default: break
        }
        return .none
    }
}

struct TestLocalState: GameState {
    var entities: EntityRepository
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
        case .incrementCount:
            state.count += 1
        default: break
        }
        return .none
    }
}
