import RedECS
import RedECSBasicComponents

public struct FollowedByCameraComponent: GameComponent {
    public var entity: EntityId
    public init(entity: EntityId) {
        self.entity = entity
    }
}

public struct FollowedByCameraReducerContext: GameState {
    public var entities: EntityRepository
    public var position: [EntityId: PositionComponent]
    public var followedByCamera: [EntityId: FollowedByCameraComponent]
    public init(
        entities: EntityRepository,
        position: [EntityId: PositionComponent],
        followedByCamera: [EntityId: FollowedByCameraComponent]
    ) {
        self.entities = entities
        self.position = position
        self.followedByCamera = followedByCamera
    }
}
