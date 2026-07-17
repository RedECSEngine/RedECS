import Geometry
import RedECS

public protocol HUDRenderableGameState: GameState {
    var hud: [EntityId: HUDComponent] { get }
}

/// Renders every `HUDComponent` in screen space each frame. Runs after the
/// world `RenderingReducer` in a game's reducer chain; needs no camera —
/// the layout space is the viewport (top-left origin, y-down) and the
/// renderer projects `.screen` groups independently of the world.
public struct HUDRenderingReducer<ContextState: HUDRenderableGameState>: Reducer {
    public typealias State = ContextState
    public typealias Action = Never
    public typealias Environment = RenderingEnvironment

    public init() {}

    public func reduce(
        state: inout State,
        delta: Double,
        environment: RenderingEnvironment
    ) -> GameEffect<State, Never> {
        let viewport = environment.renderer.viewportSize
        guard viewport.width > 0, viewport.height > 0 else { return .none }

        let components = state.hud.values
            .sorted { ($0.zIndex, $0.entity) < ($1.zIndex, $1.entity) }

        var z = 0
        for component in components {
            guard let root = component.content else { continue }
            let context = HUDRenderContext(
                fonts: environment.resourceManager.fonts
            )
            let rootSize = root.size(proposed: ProposedSize(viewport), context: context)
            let offset = Alignment.center.offset(forChild: rootSize, in: viewport)
            let groups = root.render(context: context, size: rootSize)
                .map { group -> RenderGroup in
                    defer { z += 1 }
                    return group
                        .reparented(by: offset)
                        .with(zIndex: z, projectionSpace: .screen)
                }
            environment.renderer.enqueue(groups)
        }
        return .none
    }
}
