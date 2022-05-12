import RedECSRenderingComponents
import RedECS

public struct FollowedByCameraReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout FollowedByCameraReducerContext,
        delta: Double,
        environment: SpriteKitRenderingEnvironment
    ) -> GameEffect<FollowedByCameraReducerContext, Never> {
        if let id = state.followedByCamera.values.first?.entity,
              let position = state.position[id]  {
            environment.renderer.scene.camera?.position = .init(
                x: position.point.x,
                y: position.point.y
            )
        }
        return .none
    }
}
