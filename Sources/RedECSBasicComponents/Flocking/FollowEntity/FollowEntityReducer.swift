import RedECS
import Geometry

public struct FollowEntityReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var position: [EntityId: PositionComponent]
    public var movement: [EntityId: MovementComponent]
    public var followEntity: [EntityId: FollowEntityComponent]
    
    public init(
        entities: EntityRepository = .init(),
        position: [EntityId : PositionComponent],
        movement: [EntityId : MovementComponent],
        followEntity: [EntityId : FollowEntityComponent]
    ) {
        self.entities = entities
        self.position = position
        self.movement = movement
        self.followEntity = followEntity
    }
}

public struct FollowEntityReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout FollowEntityReducerContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<FollowEntityReducerContext, Never> {
        state.followEntity.forEach { (id, following) in
            guard let entityPosition = state.position[id],
                  let followingPosition = state.position[following.leaderId]
            else { return }
            
            let distance: Double = entityPosition.point.distanceFrom(followingPosition.point)
            if distance >= following.maxDistance {
                var vector = followingPosition.point.diffOf(entityPosition.point)
                vector.normalize(to: 1)
                state.movement[id]?.velocity += vector
            }
        }
        return .none
    }
}
