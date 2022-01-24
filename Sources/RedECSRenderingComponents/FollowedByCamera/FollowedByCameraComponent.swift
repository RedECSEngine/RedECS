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

public struct FollowedByCameraReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout FollowedByCameraReducerContext,
        delta: Double,
        environment: SpriteRenderingEnvironment
    ) -> GameEffect<FollowedByCameraReducerContext, Never> {
        if let id = state.followedByCamera.values.first?.entity,
              let position = state.position[id]  {
            environment.renderer.setCameraPosition(.init(x: position.point.x, y: position.point.y))
        }
        return .none
    }
}
