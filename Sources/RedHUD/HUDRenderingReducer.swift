import Geometry
import RedECS

/// Renders a HUD each frame from a single view tree that can mix **screen**
/// and **world** space. The initializer takes a function from game state to
/// the HUD's root view, so the HUD is always derived from — and in sync with —
/// state; return nil to hide it entirely. Screen content (`ScreenSpace`/`Pin`,
/// or a bare stack) maps to viewport points; world content (`WorldSpace`/
/// `WorldPosition`) is projected by the primary camera and pans/zooms with the
/// scene. `Viewport`/`Layer` compose the two and order their layers.
///
/// Compose it **after** the world `RenderingReducer`, which sets the camera
/// projection this reducer's world groups ride. The state is constrained to
/// `RenderableGameState` so a camera is always part of the model. Every emitted
/// group is offset by `baseZIndex` (default 1000) so world HUD paints above the
/// scene's sprites; screen groups draw above all world groups regardless.
///
/// `GameAction` is the game's own action type, fired by `Button`s (screen
/// space only for now): forward pointer events in as `HUDAction` cases and map
/// `.triggered` back out (see `HUDAction`). HUDs without buttons use `Never`.
public struct HUDRenderingReducer<ContextState: RenderableGameState, GameAction: Equatable & Codable>: Reducer {
    public typealias State = ContextState
    public typealias Action = HUDAction<GameAction>
    public typealias Environment = RenderingEnvironment

    let content: (ContextState) -> AnyHUDView?
    /// Draw-order base for every emitted group; the default clears typical
    /// sprite `zIndex`es so world HUD content paints above the scene.
    var baseZIndex: Int
    let cache = HUDCache()

    /// Pointer travel (points) past which a press is treated as a scroll drag
    /// and its button tap is suppressed on release.
    static var dragThreshold: Double { 4 }

    public init(baseZIndex: Int = 1000, content: @escaping (ContextState) -> AnyHUDView?) {
        self.baseZIndex = baseZIndex
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
        cache.beginScrollFrame()
        let tree = root.resolve(proposed: ProposedSize(viewport), context: context)
        cache.endAnimationFrame()
        cache.endScrollFrame()
        let offset = Alignment.center.offset(forChild: tree.frame.size, in: viewport)
        cache.lastTree = tree
        cache.lastViewport = viewport
        cache.lastRootOffset = offset
        var z = baseZIndex
        let groups = tree.flattenedGroups()
            .map { group -> RenderGroup in
                defer { z += 1 }
                // The center offset positions screen content in the viewport;
                // world content carries its own world coordinates and must not
                // be shifted by it.
                let positioned = group.projectionSpace == .screen
                    ? group.reparented(by: offset)
                    : group
                return positioned.with(zIndex: z, projectionSpace: group.projectionSpace)
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
            // Capture a drag to the enclosing scroll region, if any.
            if let scroll = result?.scroll {
                cache.activeScroll = (scroll.identity, point, 0)
            }
            return trigger(result?.hit?.down)

        case .pointerMove(let point):
            // An active scroll drag beats hover: accumulate the delta into the
            // region's offset (content follows the pointer) and seed velocity.
            if var drag = cache.activeScroll {
                let delta = point.diffOf(drag.lastPoint)
                drag.moved += abs(delta.x) + abs(delta.y)
                drag.lastPoint = point
                cache.activeScroll = drag
                var slot = cache.scrollSlots[drag.identity] ?? ScrollState()
                let axisDelta = slot.axis == .horizontal ? delta.x : delta.y
                let moved = (slot.offset(along: slot.axis) - axisDelta).clamped(to: slot.range)
                slot.setOffset(moved, along: slot.axis)
                slot.velocity = -axisDelta
                cache.scrollSlots[drag.identity] = slot
                return .none
            }
            let result = hitResult(at: point)
            guard result?.identity != cache.hoveredIdentity else {
                return .none
            }
            cache.hoveredIdentity = result?.identity
            // fires on enter only; leaving (or crossing to nothing) is silent
            return trigger(result?.hit?.hover)

        case .pointerUp(let point):
            // A drag past the threshold suppresses the button tap.
            let wasDrag = (cache.activeScroll?.moved ?? 0) > Self.dragThreshold
            cache.activeScroll = nil
            let pressed = cache.pressedIdentity
            cache.pressedIdentity = nil
            guard !wasDrag, let result = hitResult(at: point),
                  result.identity == pressed else {
                return .none
            }
            return trigger(result.hit?.up)

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
