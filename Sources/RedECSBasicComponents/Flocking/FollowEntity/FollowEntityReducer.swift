import RedECS
import Geometry

public struct FollowEntityReducerContext: GameState {
    public var entities: EntityRepository = .init()
    public var transform: [EntityId: TransformComponent]
    public var movement: [EntityId: MovementComponent]
    public var followEntity: [EntityId: FollowEntityComponent]
    
    public init(
        entities: EntityRepository = .init(),
        transform: [EntityId: TransformComponent],
        movement: [EntityId : MovementComponent],
        followEntity: [EntityId : FollowEntityComponent]
    ) {
        self.entities = entities
        self.transform = transform
        self.movement = movement
        self.followEntity = followEntity
    }
}
//
//public struct FollowEntityReducer: Reducer {
//    public init() {}
//    public func reduce(
//        state: inout FollowEntityReducerContext,
//        delta: Double,
//        environment: Void
//    ) -> GameEffect<FollowEntityReducerContext, Never> {
//        state.followEntity.forEach { (id, following) in
//            guard let entityTransform = state.transform[id],
//                  let followingTransform = state.transform[following.leaderId]
//            else { return }
//            
//            let distance: Double = entityTransform.position.distanceFrom(followingTransform.position)
//            if distance >= following.maxDistance {
//                var vector = followingTransform.position.diffOf(entityTransform.position)
//                vector.normalize(to: 1)
//                state.movement[id]?.velocity += vector
//            }
//        }
//        return .none
//    }
//}
