import Geometry
import RedECS

/// Renders a HUD over the world each frame in screen space (top-left origin,
/// y-down viewport points), camera-free. The initializer takes a function
/// from game state to the HUD's root view, so the HUD is always derived
/// from — and in sync with — state; return nil to hide the HUD entirely.
/// Compose it after the world `RenderingReducer` in a game's reducer chain.
public struct HUDRenderingReducer<ContextState: GameState>: Reducer {
    public typealias State = ContextState
    public typealias Action = Never
    public typealias Environment = RenderingEnvironment

    let content: (ContextState) -> AnyHUDView?
    let cache = HUDCache()

    public init(content: @escaping (ContextState) -> AnyHUDView?) {
        self.content = content
    }

    public func reduce(
        state: inout ContextState,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<ContextState, Never> {
        let viewport = environment.renderer.viewportSize
        guard viewport.width > 0, viewport.height > 0,
              let root = content(state) else {
            cache.clear()
            return .none
        }

        var context = HUDRenderContext(
            resourceManager: environment.resourceManager
        )
        context.cache = cache
        context.delta = delta
        cache.beginAnimationFrame()
        let tree = root.resolve(proposed: ProposedSize(viewport), context: context)
        cache.endAnimationFrame()
        let offset = Alignment.center.offset(forChild: tree.frame.size, in: viewport)
        cache.lastTree = tree
        cache.lastViewport = viewport
        cache.lastRootOffset = offset
        var z = 0
        let groups = tree.flattenedGroups()
            .map { group -> RenderGroup in
                defer { z += 1 }
                return group
                    .reparented(by: offset)
                    .with(zIndex: z, projectionSpace: .screen)
            }
        environment.renderer.enqueue(groups)
        return .none
    }
}
