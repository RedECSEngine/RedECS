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
            return .none
        }

        let context = HUDRenderContext(
            fonts: environment.resourceManager.fonts
        )
        let rootSize = root.size(proposed: ProposedSize(viewport), context: context)
        let offset = Alignment.center.offset(forChild: rootSize, in: viewport)
        var z = 0
        let groups = root.render(context: context, size: rootSize)
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
