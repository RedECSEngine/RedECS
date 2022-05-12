import RedECS
import Geometry

public struct MomentumReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var momentum: [EntityId: MomentumComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]
    
    public init(
        entities: EntityRepository = .init(),
        momentum: [EntityId : MomentumComponent] = [:],
        movement: [EntityId : MovementComponent] = [:]
    ) {
        self.entities = entities
        self.momentum = momentum
        self.movement = movement
    }
}

public struct MomentumReducer: Reducer {
    public init() { }
    public func reduce(
        state: inout MomentumReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<MomentumReducerContext, Never> {
        state.momentum.forEach { (id, momentum) in
            guard var move = state.movement[id] else { return }
            move.velocity += momentum.velocity
            state.movement[id] = move
        }
        return .none
    }
}
