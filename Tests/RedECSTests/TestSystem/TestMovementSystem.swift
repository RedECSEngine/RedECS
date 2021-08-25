import Foundation
import RedECS

struct TestMovementComponent: GameComponent {
    var entity: EntityId
    var velocity: Point
}

struct TestMovementComponentState: GameState {
    var entities: Set<EntityId>
    var positions: [EntityId: TestPositionComponent]
    var movement: [EntityId: TestMovementComponent]
}

struct TestMovementReducer: Reducer {
    func reduce(state: inout TestMovementComponentState, delta: Double, environment: TestGlobalEnvironment) -> GameEffect<TestMovementComponentState, TestGlobalAction> {
            .none
    }
    
    typealias State = TestMovementComponentState
    typealias Action = TestGlobalAction
    typealias Environment = TestGlobalEnvironment
    
    func reduce(
        state: inout TestMovementComponentState,
        action: TestGlobalAction,
        environment: TestGlobalEnvironment
    ) -> GameEffect<TestMovementComponentState, TestGlobalAction> {
        switch action {
        case .tick:
            state.movement.forEach { (id, movement) in
                guard movement.velocity != .zero else { return }
                guard var position = state.positions[id] else { return }
                
                position.x += movement.velocity.x
                position.y += movement.velocity.y
                
                state.positions[id] = position
            }
        case .updateVelocity(let entity, let velocity):
            state.movement[entity]?.velocity = velocity
        default:
            break
        }
        return .none
    }
}
