import RedECS
import Geometry

public struct MovementReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var position: [EntityId: PositionComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]
    
    public init(
        entities: EntityRepository = .init(),
        position: [EntityId : PositionComponent] = [:],
        movement: [EntityId : MovementComponent] = [:]
    ) {
        self.entities = entities
        self.position = position
        self.movement = movement
    }
}

public struct MovementReducer: Reducer {
    public init() { }
    public func reduce(
        state: inout MovementReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<MovementReducerContext, Never> {
        state.movement.forEach { (id, movement) in
            var movement = movement
            guard var point = state.position[id]?.point else { return }
            let deltaVelocity = movement.velocity * delta
            
            movement.recentVelocityHistory.append(deltaVelocity)
            movement.recentVelocityHistory = Array(movement.recentVelocityHistory.suffix(1))
            movement.velocity = .zero
            
            let avgVelocity = movement.recentVelocityHistory.reduce(Point.zero, +) / Double(movement.recentVelocityHistory.count)
            point += (avgVelocity * movement.travelSpeed)
            
            state.position[id]?.point = point
            state.movement[id] = movement
        }
        return .none
    }
}
