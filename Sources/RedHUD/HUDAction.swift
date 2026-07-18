import Geometry

/// The HUD reducer's action vocabulary. Games forward platform pointer
/// events (in viewport points, top-left origin y-down — web canvas
/// coordinates directly; flip macOS view coordinates) wrapped in their own
/// action type, and receive button fires back out. Two proven wirings:
///
/// **Dedicated command type** (recommended — no recursive enum anywhere):
/// buttons fire a small HUD-command enum, and the game's own reducer
/// observes the wrapped `.triggered`:
///
///     enum HUDCommand: Equatable { case pause, buyItem(String) }
///     enum GameAction: Equatable {
///         case hud(HUDAction<HUDCommand>)
///         // ...the game's other actions
///     }
///
///     HUDRenderingReducer<MyState, HUDCommand> { state in ... }
///         .pullback(
///             toLocalState: \.self,
///             toLocalAction: { (action: GameAction) in
///                 if case .hud(let hudAction) = action { return hudAction }
///                 return nil
///             },
///             toGlobalAction: { GameAction.hud($0) },
///             toLocalEnvironment: { $0 as RenderingEnvironment }
///         )
///
/// A tap flows: `.hud(.pointerUp(p))` → HUD reducer emits
/// `.triggered(.pause)` → wrapped back as `.hud(.triggered(.pause))` →
/// the HUD reducer ignores `.triggered` (ending the hop) while the game's
/// reducer pattern-matches `.hud(.triggered(let command))` and acts.
///
/// **Top-level actions directly**: buttons carry the game's action enum
/// itself. The embedding case must then be `indirect`, and `toGlobalAction`
/// unwraps `.triggered` straight into the action:
///
///     indirect enum GameAction: Equatable {
///         case hud(HUDAction<GameAction>)
///         case pausePressed
///     }
///
///     toGlobalAction: { hudAction in
///         if case .triggered(let action) = hudAction { return action }
///         return .hud(hudAction)  // unreachable: only .triggered is emitted
///     }
public enum HUDAction<GameAction: Equatable>: Equatable {
    case pointerDown(Point)
    case pointerUp(Point)
    case pointerMove(Point)
    /// Emitted BY the reducer when a button fires; never send it inbound.
    case triggered(GameAction)
}
