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
    public var transform: [EntityId: TransformComponent]
    public var followedByCamera: [EntityId: FollowedByCameraComponent]
    public init(
        entities: EntityRepository,
        transform: [EntityId: TransformComponent],
        followedByCamera: [EntityId: FollowedByCameraComponent]
    ) {
        self.entities = entities
        self.transform = transform
        self.followedByCamera = followedByCamera
    }
}
