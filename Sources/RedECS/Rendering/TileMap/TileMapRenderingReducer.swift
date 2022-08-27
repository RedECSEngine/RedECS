import Geometry
import GeometryAlgorithms

public struct TileMapRenderingReducer: Reducer {
    public init() {}
    public func reduce(
        state: inout TileMapRenderingReducerContext,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<TileMapRenderingReducerContext, Never> {
        state.tileMap.forEach { (id, tileMap) in
            guard let transform = state.transform[id] else { return }
            environment.renderer.enqueue(
                tileMap.renderGroups(
                    transform: transform,
                    resourceManager: environment.resourceManager
                )
            )
        }
        return .none
    }
}
