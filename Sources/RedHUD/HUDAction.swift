import Geometry

/// The HUD reducer's action vocabulary. Games forward platform pointer
/// events (in viewport points, top-left origin y-down — web canvas
/// coordinates directly; flip macOS view coordinates) and map `.triggered`
/// back out to their own action type via pullback:
///
///     HUDRenderingReducer<MyState, MyAction> { state in ... }
///         .pullback(
///             toLocalState: \.self,
///             toLocalAction: { globalAction in
///                 if case .pointer(let event) = globalAction { return event }
///                 return nil
///             },
///             toGlobalAction: { hudAction in
///                 guard case .triggered(let action) = hudAction else { ... }
///                 return action
///             },
///             toLocalEnvironment: { $0 as RenderingEnvironment }
///         )
public enum HUDAction<GameAction: Equatable>: Equatable {
    case pointerDown(Point)
    case pointerUp(Point)
    case pointerMove(Point)
    /// Emitted BY the reducer when a button fires; never send it inbound.
    case triggered(GameAction)
}
