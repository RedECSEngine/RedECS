import RedECS
import Geometry

public struct MovementReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var transform: [EntityId: TransformComponent] = [:]
    public var movement: [EntityId: MovementComponent] = [:]
    
    public init(
        entities: EntityRepository = .init(),
        transform: [EntityId: TransformComponent] = [:],
        movement: [EntityId : MovementComponent] = [:]
    ) {
        self.entities = entities
        self.transform = transform
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
            guard var point = state.transform[id]?.position else { return }
            let deltaVelocity = movement.velocity * delta
            
            movement.recentVelocityHistory.append(deltaVelocity)
            movement.recentVelocityHistory = Array(movement.recentVelocityHistory.suffix(1))
            movement.velocity = .zero
            
            let avgVelocity = movement.recentVelocityHistory.reduce(Point.zero, +) / Double(movement.recentVelocityHistory.count)
            point += (avgVelocity * movement.travelSpeed)
            
            state.transform[id]?.position = point
            state.movement[id] = movement
        }
        return .none
    }
}
