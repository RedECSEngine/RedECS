import Geometry
import RedECS

/// Renders a HUD over the world each frame in screen space (top-left origin,
/// y-down viewport points), camera-free. The initializer takes a function
/// from game state to the HUD's root view, so the HUD is always derived
/// from — and in sync with — state; return nil to hide the HUD entirely.
/// Compose it after the world `RenderingReducer` in a game's reducer chain.
///
/// `GameAction` is the game's own action type, fired by `Button`s: forward
/// pointer events in as `HUDAction` cases and map `.triggered` back out
/// (see `HUDAction`). HUDs without buttons use `Never`.
public struct HUDRenderingReducer<ContextState: GameState, GameAction: Equatable>: Reducer {
    public typealias State = ContextState
    public typealias Action = HUDAction<GameAction>
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
    ) -> GameEffect<ContextState, Action> {
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

    public func reduce(
        state: inout ContextState,
        action: Action,
        environment: RenderingEnvironment
    ) -> GameEffect<ContextState, Action> {
        switch action {
        case .pointerDown(let point):
            let result = hitResult(at: point)
            cache.pressedIdentity = result?.identity
            return trigger(result?.hit.down)

        case .pointerUp(let point):
            let pressed = cache.pressedIdentity
            cache.pressedIdentity = nil
            guard let result = hitResult(at: point),
                  result.identity == pressed else {
                return .none
            }
            return trigger(result.hit.up)

        case .pointerMove(let point):
            let result = hitResult(at: point)
            guard result?.identity != cache.hoveredIdentity else {
                return .none
            }
            cache.hoveredIdentity = result?.identity
            // fires on enter only; leaving (or crossing to nothing) is silent
            return trigger(result?.hit.hover)

        case .triggered:
            // outbound only — the game's pullback maps it away before it
            // could ever arrive here
            return .none
        }
    }

    /// Hit-tests against the last *drawn* tree, so input lands on what the
    /// player is actually seeing.
    private func hitResult(at point: Point) -> HUDHitResult? {
        cache.lastTree?.hitTest(point.diffOf(cache.lastRootOffset))
    }

    /// The single seam where the type-erased button payload meets the
    /// game's action type again.
    private func trigger(_ payload: Any?) -> GameEffect<ContextState, Action> {
        guard let payload = payload else { return .none }
        guard let action = payload as? GameAction else {
            assertionFailure(
                "Button action \(payload) is not a \(GameAction.self); the button no-ops"
            )
            return .none
        }
        return .game(.triggered(action))
    }
}
